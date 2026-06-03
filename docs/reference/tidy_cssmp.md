# Cross-sectional probabilistic reconciliation (sample approach)

Reconciles a hierarchy or grouped time series using the
[`FoReco::cssmp()`](https://danigiro.github.io/FoReco/reference/cssmp.html)
function. The response variable of the hierarchy must be aggregated
using sums. Forecasted time points must match for all series in the
hierarchy.

## Usage

``` r
tidy_cssmp(models, simulate = TRUE, bootstrap = FALSE, times = 1000, ...)
```

## Arguments

- models:

  A column of models in a mable.

- simulate:

  Should forecasts be based on simulated future paths instead of
  analytical results.

- bootstrap:

  Should innovations from simulated forecasts be bootstrapped from the
  model's fitted residuals. This allows the forecast distribution to
  have a different underlying shape which could better represent the
  nature of your data.

- times:

  The number of future paths for simulations if `simulate = TRUE`.

- ...:

  Additional arguments passed to
  [`FoReco::cssmp()`](https://danigiro.github.io/FoReco/reference/cssmp.html),
  except for `sample`, `agg_mat`, `cons_mat`, and `res`, which are
  supplied internally.

## Value

An object of class `lst_cssmp_mdl`
