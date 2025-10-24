
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidyreco <img src="man/figures/logo.svg" alt="logo" align="right" width="150" style="border: none; float: right;"/>

<!--[![R-CMD-check](https://github.com/danigiro/tidyreco/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/danigiro/tidyreco/actions/workflows/R-CMD-check.yaml) -->

[![CRAN
status](https://www.r-pkg.org/badges/version/tidyreco)](https://CRAN.R-project.org/package=tidyreco)
[![devel
version](https://img.shields.io/badge/devel%20version-0.0.0.9000-blue.svg)](https://github.com/danigiro/tidyreco)
[![License:
GPL-3](https://img.shields.io/badge/license-GPL--3-forestgreen.svg)](https://cran.r-project.org/web/licenses/GPL-3)

The goal of tidyreco is to …

## Installation

You can install the **stable** version on [R
CRAN](https://cran.r-project.org/package=tidyreco) with:

``` r
install.packages("tidyreco")
```

You can also install the **development** version from
[Github](https://github.com/danigiro/tidyreco)

``` r
# install.packages("devtools")
devtools::install_github("danigiro/tidyreco")
```

## Example

``` r
library(fable)
library(tidyreco)
library(ggplot2)

data <- tsibble::tourism |>
  aggregate_key(Purpose, Trips = sum(Trips)) |>
  model(ets = ETS(Trips)) |>
  reconcile(
    csrec = tidy_csrec(ets, comb = "wls"),
    csmvn = tidy_csmvn(ets, comb = "wls"),
    cssmp100 = tidy_cssmp(ets, comb = "wls", times = 100),
    cssmp1000 = tidy_cssmp(ets, comb = "wls", times = 1000),
    fbl = min_trace(ets)
  ) |>
  forecast()

data |>
  dplyr::mutate(
    .model = dplyr::recode(
      .model,
      ets = "Base forecast",
      csrec = "Point recon.",
      csmvn = "Gaussian recon.",
      cssmp100 = "Recon. with 100 samples",
      cssmp1000 = "Recon. with 1000 samples",
      fbl = "Original fable implem."
    )
  ) |>
  autoplot() +
  facet_grid(Purpose ~ .model, scales = "free") +
  labs(title = "Tourism forecasts with different reconciliation methods") +
  theme(legend.position = "bottom", 
        legend.title = element_blank(), 
        legend.box="vertical",
        legend.margin = margin())
```

<img src="man/figures/README-example-1.png" width="200%" />
