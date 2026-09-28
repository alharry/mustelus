# mustelus

Tools for chondrichthyan fisheries biology.

## Installation

Install the pre-built binary from r-universe. This needs no compiler and
no development tools on any platform:

``` r

install.packages("mustelus",
  repos = c("https://alharry.r-universe.dev", "https://cloud.r-project.org"))
```

Or build from source directly off GitHub:

``` r

# install.packages("pak")
pak::pak("alharry/mustelus")
```

### A note for Windows users

`mustelus` contains no compiled code, and every package it depends on —
including `RTMB` and `TMB` — is available from CRAN as a Windows binary.
**A compiler is not needed to install or use it.**

Installing from GitHub nonetheless goes through a source build, and
`devtools`/`remotes` check for RTools before doing so whether or not the
package actually needs it. If that check fails, it can be skipped:

``` r

options(buildtools.check = function(action) TRUE)
pak::pak("alharry/mustelus")
```

If RTools genuinely is not being recognised, the usual cause is a
version mismatch. RTools releases are tied to R releases and are not
interchangeable: RTools43 works only with R 4.3, RTools44 with R 4.4,
RTools45 with R 4.5. R will not recognise a version that does not match,
and reinstalling the wrong one will not help. Check with:

``` r

R.version.string
pkgbuild::rtools_path()
```

## Functions

- [`len_weight()`](https://alharry.github.io/mustelus/reference/len_weight.md)
  — length–weight regression with bias-corrected predictions, confidence
  and prediction intervals.
- [`maturity()`](https://alharry.github.io/mustelus/reference/maturity.md)
  — length or age at maturity via logistic regression, with bootstrap
  confidence intervals on $`L_{50}`$ and $`L_{95}`$.
- [`maternity()`](https://alharry.github.io/mustelus/reference/maternity.md)
  — length or age at maternity via the three-parameter logistic function
  of Walker (2005), with $`P_{Max}`$ either estimated or fixed,
  implemented in RTMB.
- [`fecundity()`](https://alharry.github.io/mustelus/reference/fecundity.md)
  — fecundity as a function of length or age by linear regression, with
  confidence and prediction intervals.
- [`clasp_length()`](https://alharry.github.io/mustelus/reference/clasp_length.md)
  — clasper elongation as a function of length or age by nonlinear
  (logistic) regression, with bootstrap confidence intervals.
- [`growth()`](https://alharry.github.io/mustelus/reference/growth.md) —
  von Bertalanffy growth parameterised by length at birth, with optional
  ageing error as a random effect and optional neonate data, implemented
  in RTMB.

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
