# mustelus <a href="https://alharry.github.io/mustelus/"><img src="man/figures/logo.png" align="right" height="138" alt="mustelus website" /></a>

Tools for chondrichthyan fisheries biology.

## Installation

``` r
# install.packages("pak")
pak::pak("alharry/mustelus")
```

## Functions

- `len_weight()` — length–weight regression with bias-corrected predictions,
  confidence and prediction intervals.
- `maturity()` — length or age at maturity via logistic regression, with
  bootstrap confidence intervals on $L_{50}$ and $L_{95}$.
- `fecundity()` — fecundity as a function of length or age by linear
  regression, with confidence and prediction intervals.

Each returns a tibble with list columns holding the data, coefficients,
predictions and fitted model, and has `summary()` and `plot()` methods.
`len_weight()` and `maturity()` accept an optional grouping variable and fit
one model per group plus a pooled group. See the
[articles](https://alharry.github.io/mustelus/articles/) for worked examples.