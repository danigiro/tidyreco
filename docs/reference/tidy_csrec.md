# Optimal combination cross-sectional reconciliation

Reconciles a hierarchy or grouped time series using the
[`FoReco::csrec()`](https://danigiro.github.io/FoReco/reference/csrec.html)
function. The response variable of the hierarchy must be aggregated
using sums. Forecasted time points must match for all series in the
hierarchy.

## Usage

``` r
tidy_csrec(models, ...)
```

## Arguments

- models:

  A column of models in a mable.

- ...:

  Additional arguments passed to
  [`FoReco::csrec()`](https://danigiro.github.io/FoReco/reference/csrec.html),
  except for `base`, `agg_mat`, `cons_mat`, and `res`, which are
  supplied internally.

## Value

An object of class `lst_csrec_mdl`
