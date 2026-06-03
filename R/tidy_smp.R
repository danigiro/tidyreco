#' Cross-sectional probabilistic reconciliation (sample approach)
#'
#' Reconciles a hierarchy or grouped time series using the [FoReco::cssmp()]
#' function. The response variable of the hierarchy must be aggregated using
#' sums. Forecasted time points must match for all series in the hierarchy.
#'
#' @param models A column of models in a mable.
#' @param simulate Should forecasts be based on simulated future paths instead
#' of analytical results.
#' @param bootstrap Should innovations from simulated forecasts be bootstrapped
#' from the model's fitted residuals. This allows the forecast distribution to
#' have a different underlying shape which could better represent the nature
#' of your data.
#' @param times The number of future paths for simulations if `simulate = TRUE`.
#' @param ... Additional arguments passed to [FoReco::cssmp()], except for
#'   `sample`, `agg_mat`, `cons_mat`, and `res`, which are supplied internally.
#'
#' @return An object of class `lst_cssmp_mdl`
#'
#' @export
tidy_cssmp <- function(
  models,
  simulate = TRUE,
  bootstrap = FALSE,
  times = 1000,
  ...
) {
  structure(
    models,
    class = c("lst_cssmp_mdl", "lst_mdl", "list"),
    simulate = simulate,
    bootstrap = bootstrap,
    times = times,
    FoReco = list(...)
  )
}

#' @export
forecast.lst_cssmp_mdl <- function(
  object,
  key_data,
  new_data = NULL,
  h = NULL,
  point_forecast = list(.mean = mean),
  ...
) {
  FoReco_input <- object %@% "FoReco"

  dots_list <- list(...)
  if (is.null(dots_list$simulate)) {
    simulate <- object %@% "simulate"
  } else {
    simulate <- dots_list$simulate
  }

  if (is.null(dots_list$bootstrap)) {
    bootstrap <- object %@% "bootstrap"
  } else {
    bootstrap <- dots_list$bootstrap
  }

  if (is.null(dots_list$times)) {
    times <- object %@% "times"
  } else {
    times <- dots_list$times
  }

  if (is.null(FoReco_input$comb)) {
    FoReco_input$comb <- "shr"
  }

  # Get forecasts
  fc <- NextMethod(simulate = simulate, times = times, bootstrap = bootstrap)

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

  sample_size <- unique(unlist(lapply(fc_dist, function(x) {
    unique(lengths(parameters(x)$x))
  })))
  if (length(sample_size) != 1L) {
    stop("Cannot reconcile sample paths with different replication sizes.")
  }
  sample_horizon <- unique(lengths(fc_dist))
  if (length(sample_horizon) != 1L) {
    stop(
      "Cannot reconcile sample paths with different forecast horizon lengths."
    )
  }
  # Extract sample paths
  samples <- lapply(fc_dist, function(x) parameters(x)$x)
  samples <- aperm(
    array(
      unlist(samples, use.names = FALSE),
      dim = c(sample_size, sample_horizon, length(fc_dist))
    ),
    c(2, 3, 1)
  )
  samples <- samples[, c(row_agg, row_btm), , drop = FALSE]

  tmp <- suppressWarnings(
    do.call(
      cssmp,
      c(
        list(
          sample = samples,
          agg_mat = agg_mat,
          res = res[, c(row_agg, row_btm), drop = FALSE]
        ),
        FoReco_input
      )
    )
  )
  names(tmp) <- NULL
  samples <- simplify2array(lapply(vec_data(tmp), function(x) x$x))
  samples <- samples[, order(c(row_agg, row_btm)), , drop = FALSE]
  fc_dist <- apply(
    samples,
    2L,
    simplify = FALSE,
    function(x) unname(dist_sample(split(t(x), 1:ncol(x))))
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
