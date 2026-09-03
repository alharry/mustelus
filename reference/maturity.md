# Analyse length or age at maturity

Fits a logistic regression model (binomial GLM) of maturity stage as a
function of length, age, or another continuous predictor. Bootstrap
confidence intervals are computed via `rsample`.

## Usage

``` r
maturity(mat, x, grouping_var = NULL, data, times = 1000)
```

## Arguments

- mat:

  Binary maturity variable (0 = immature, 1 = mature)

- x:

  Continuous predictor variable (e.g. length, age)

- grouping_var:

  Optional categorical grouping variable (e.g. sex). Will be converted
  to a factor.

- data:

  A data frame containing the above variables

- times:

  Number of bootstrap replicates (default 1000)

## Value

A nested tibble of class `"maturity"` with one row per group, containing
list columns `data`, `coefs`, `preds`, and `mods`, each named by the
grouping variable level.

## Examples

``` r
data(spottail)

lm50 <- maturity(maturity_stage, length, sex, data = spottail, times = 100)
#> The categorical variable sex has 2 levels.
#> Warning: There was 1 warning in `mutate()`.
#> ℹ In argument: `.fit = map(data, ~maturity_mod(.x))`.
#> ℹ In group 2: `grouping_var = "f"`.
#> Caused by warning:
#> ! glm.fit: fitted probabilities numerically 0 or 1 occurred

summary(lm50)
#> # A tibble: 3 × 10
#>        a      b   L50 L50_lower L50_upper   L95 L95_lower L95_upper     n     N
#>    <dbl>  <dbl> <dbl>     <dbl>     <dbl> <dbl>     <dbl>     <dbl> <int> <int>
#> 1  -55.4 0.0594  934.      925.      941   983.      966.      996    430   341
#> 2 -124.  0.131   951.      939.      962.  973.      942.      992.   118    97
#> 3  -51.1 0.0550  929.      921.      937.  983.      964.     1004    312   244

plot(lm50)
#> $all

#> 
#> $f

#> 
#> $m

#> 
```
