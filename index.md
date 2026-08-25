# mustelus

Tools for chondrichthyan fisheries biology.

## Installation

``` r

# install.packages("pak")
pak::pak("alharry/mustelus")
```

## Functions

- [`len_weight()`](https://alharry.github.io/mustelus/reference/len_weight.md)
  — length–weight regression with bias-corrected predictions, confidence
  and prediction intervals.
- [`maturity()`](https://alharry.github.io/mustelus/reference/maturity.md)
  — length or age at maturity via logistic regression, with bootstrap
  confidence intervals on $`L_{50}`$ and $`L_{95}`$.
- [`fecundity()`](https://alharry.github.io/mustelus/reference/fecundity.md)
  — fecundity as a function of length or age by linear regression, with
  confidence and prediction intervals.
- [`clasp_length()`](https://alharry.github.io/mustelus/reference/clasp_length.md)
  — clasper elongation as a function of length or age by nonlinear
  (logistic) regression, with bootstrap confidence intervals.

Each returns a tibble with list columns holding the data, coefficients,
predictions and fitted model, and has
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods.
[`len_weight()`](https://alharry.github.io/mustelus/reference/len_weight.md)
and
[`maturity()`](https://alharry.github.io/mustelus/reference/maturity.md)
accept an optional grouping variable and fit one model per group plus a
pooled group. See the
[articles](https://alharry.github.io/mustelus/articles/) for worked
examples.
