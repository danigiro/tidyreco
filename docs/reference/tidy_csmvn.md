# Cross-sectional Gaussian probabilistic reconciliation

Reconciles a hierarchy or grouped time series using the
[`FoReco::csmvn()`](https://danigiro.github.io/FoReco/reference/csmvn.html)
function. The response variable of the hierarchy must be aggregated
using sums. Forecasted time points must match for all series in the
hierarchy.

## Usage

``` r
tidy_csmvn(models, ...)
```

## Arguments

- models:

  A column of models in a mable.

- ...:

  Additional arguments passed to
  [`FoReco::csmvn()`](https://danigiro.github.io/FoReco/reference/csmvn.html),
  except for `base`, `agg_mat`, `cons_mat`, and `res`, which are
  supplied internally.

## Value

An object of class `lst_csmvn_mdl`
