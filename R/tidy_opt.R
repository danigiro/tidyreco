#' Optimal combination cross-sectional reconciliation
#'
#' Reconciles a hierarchy or grouped time series using the [FoReco::csrec()]
#' function. The response variable of the hierarchy must be aggregated using
#' sums. Forecasted time points must match for all series in the hierarchy.
#'
#' @param models A column of models in a mable.
#' @param ... Additional arguments passed to [FoReco::csrec()], except for
#'   `base`, `agg_mat`, `cons_mat`, and `res`, which are supplied internally.
#'
#' @return An object of class `lst_csrec_mdl`
#'
#' @export
tidy_csrec <- function(models, ...) {
  structure(
    models,
    class = c("lst_csrec_mdl", "lst_mdl", "list"),
    FoReco = list(...)
  )
}

#' @export
forecast.lst_csrec_mdl <- function(
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

  agg_mat <- coherent_smat(key_data, sparse = TRUE, with_bottom = FALSE)
  row_btm <- attr(agg_mat, "bottom")
  row_agg <- seq_len(nrow(key_data))[-row_btm]

  fc_dist <- map(fc, function(x) x[[distribution_var(x)]])
  dist_type <- lapply(fc_dist, function(x) unique(dist_types(x)))
  dist_type <- unique(unlist(dist_type))
  is_normal <- all(map_lgl(fc_dist, function(x) {
    all(dist_types(x) == "dist_normal")
  }))

  fc_mean <- as.matrix(exec("cbind", !!!map(fc_dist, mean)))

  fc_mean <- suppressWarnings(
    do.call(
      csrec,
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
  fc_mean <- fc_mean[, order(c(row_agg, row_btm)), drop = FALSE]
  fc_mean <- split(t(fc_mean), 1:ncol(fc_mean))
  fc_dist <- map(fc_mean, dist_degenerate)

  # Update fables
  map2(fc, fc_dist, function(fc, dist) {
    dimnames(dist) <- dimnames(fc[[distribution_var(fc)]])
    fc[[distribution_var(fc)]] <- dist
    point_fc <- map(point_forecast, calc, dist)
    fc[names(point_fc)] <- point_fc
    fc
  })
}
