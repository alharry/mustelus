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
  and optionally sex

## Value

results A list containing the `lm` model, coefficients and other useful
info, predicted mean and raw data

## Examples

``` r
data(spottail)

lw <- len_weight(wgt, length, sex, data = spottail)
#> Loading required package: tidyverse
#> Warning: there is no package called ‘tidyverse’
#> Error in tibble(length = eval(arguments$length, data), weight = eval(arguments$weight,     data)): could not find function "tibble"

summary(lw)
#> Error: object 'lw' not found

p <- plot(lw)
#> Error: object 'lw' not found

p$f + xlab("Total Length (mm)") + ylab("Weight (kg)")
#> Error: object 'p' not found
```
