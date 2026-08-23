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

Both return a nested tibble with one row per group and have
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods. See
the [articles](https://alharry.github.io/mustelus/articles/) for worked
examples.
