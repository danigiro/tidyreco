#' Cross-sectional Gaussian probabilistic reconciliation
#'
#' Reconciles a hierarchy or grouped time series using the [FoReco::csmvn()]
#' function. The response variable of the hierarchy must be aggregated using
#' sums. Forecasted time points must match for all series in the hierarchy.
#'
#' @param models A column of models in a mable.
#' @param ... Additional arguments passed to [FoReco::csmvn()], except for
#'   `base`, `agg_mat`, `cons_mat`, and `res`, which are supplied internally.
#'
#' @return An object of class `lst_csmvn_mdl`
#'
#' @export
tidy_csmvn <- function(models, ...) {
  structure(
    models,
    class = c("lst_csmvn_mdl", "lst_mdl", "list"),
    FoReco = list(...)
  )
}

#' @export
forecast.lst_csmvn_mdl <- function(
  object,
  key_data,
  new_data = NULL,
  h = NULL,
  point_forecast = list(.mean = mean),
  ...
) {
  FoReco_input <- object %@% "FoReco"

  if (is.null(FoReco_input$comb)) {
    FoReco_input$comb <- "shr"
  }

  # Get forecasts
  fc <- NextMethod()

  if (length(unique(map(fc, interval))) > 1) {
    abort(
      "Reconciliation of temporal hierarchies is available with tidy_terec."
    )
  }

  # Compute weights (sample covariance)
  res <- map(object, function(x, ...) residuals(x, ...), type = "response")
  if (length(unique(map_dbl(res, nrow))) > 1) {
    res <- unname(as.matrix(reduce(res, full_join, by = index_var(res[[1]]))[,
      -1
    ]))
  } else {
    res <- matrix(exec("c", !!!map(res, `[[`, 2)), ncol = length(object))
  }

  agg_data <- fabletools:::build_key_data_smat(key_data)
  row_btm <- agg_data$leaf
  row_agg <- seq_len(nrow(key_data))[-row_btm]
  agg_data_A <- agg_data$agg[-row_btm]
  agg_mat <- sparseMatrix(
    i = rep(seq_along(agg_data_A), lengths(agg_data_A)),
    j = vec_c(!!!agg_data_A),
    x = rep(1, sum(lengths(agg_data_A)))
  )

  fc_dist <- map(fc, function(x) x[[distribution_var(x)]])
  dist_type <- lapply(fc_dist, function(x) unique(dist_types(x)))
  dist_type <- unique(unlist(dist_type))
  is_normal <- all(map_lgl(fc_dist, function(x) {
    all(dist_types(x) == "dist_normal")
  }))

  fc_mean <- as.matrix(exec("cbind", !!!map(fc_dist, mean)))

  tmp <- suppressWarnings(
    do.call(
      csmvn,
      c(
        list(
          base = fc_mean[, c(row_agg, row_btm), drop = FALSE],
          agg_mat = agg_mat,
          res = res[, c(row_agg, row_btm), drop = FALSE]
        ),
        FoReco_input
      )
    )
  )
  fc_mean <- mean(tmp)
  fc_mean <- split(
    t(fc_mean[, order(c(row_agg, row_btm))]),
    1:ncol(fc_mean)
  )
  fc_sd <- rbind(sqrt(variance(tmp)))
  fc_sd <- fc_sd[, order(c(row_agg, row_btm)), drop = FALSE]
  fc_sd <- split(t(fc_sd), 1:ncol(fc_sd))
  fc_dist <- map2(
    fc_mean,
    fc_sd,
    dist_normal
  )

  # Update fables
  map2(fc, fc_dist, function(fc, dist) {
    dimnames(dist) <- dimnames(fc[[distribution_var(fc)]])
    fc[[distribution_var(fc)]] <- dist
    point_fc <- map(point_forecast, calc, dist)
    fc[names(point_fc)] <- point_fc
    fc
  })
}
