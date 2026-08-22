# Analyse weight-length relationship

Function for running a log-linear regression model to analyse body mass
as a function of length. Essentially just a wrapper for
[`lm()`](https://rdrr.io/r/stats/lm.html) and
[`predict.lm()`](https://rdrr.io/r/stats/predict.lm.html) that tabulates
some useful summary statistics. Also returns the predicted mean, 95
percent confidence intervals and prediction intervals, corrected for
bias due to log transformation, and the fitted
[`lm()`](https://rdrr.io/r/stats/lm.html) objects.

## Usage

``` r
len_weight(weight, length, grouping_var = NULL, data)
```

## Arguments

- weight:

  Numeric vector of weights

- length:

  Numeric vector of lengths

- grouping_var:

  Categorical variable containing two or more unique variables (e.g.
  sex). Will be converted into a factor.

- data:

  A data frame containing, minimally, variables for length and weight,
  and optionally sex or another grouping variable

## Value

results A list containing the `lm` model, coefficients and other useful
info, predicted mean and raw data

## Examples

``` r
data(spottail)

lw <- len_weight(wgt, length, sex, data = spottail)
#> The categorical variable sex has 2 levels.

summary(lw)
#> # A tibble: 3 × 8
#>          a Std.Error.range       b Std.Error  Sigma    LL     n len.range 
#>      <dbl> <chr>             <dbl> <chr>      <dbl> <dbl> <int> <chr>     
#> 1 2.13e-10 ( 1.441 - 3.16 )   3.47 ( 0.057 ) 0.102  166.    192 478 - 1301
#> 2 1.12e-10 ( 0.618 - 2.037 )  3.56 ( 0.086 ) 0.0968  91.7    99 691 - 1301
#> 3 4.47e-10 ( 2.457 - 8.148 )  3.36 ( 0.087 ) 0.107   76.9    93 478 - 1139

p <- plot(lw)

p$f + xlab("Total Length (mm)") + ylab("Weight (kg)")
#> Error in xlab("Total Length (mm)"): could not find function "xlab"
```
