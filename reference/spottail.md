# Spot-tail shark data

A dataset containing life history information for 659 spot-tail sharks,
*Carcharhinus sorrah*, collected from north-eastern Australia.

## Usage

``` r
spottail
```

## Format

A data frame with 659 rows and 27 variables:

- month:

  Month, integer form

- year:

  Calendar year

- date:

  Date collected

- jday:

  Day of year

- tag:

  Identification number

- FL:

  Fork length (mm)

- TL:

  Total length (mm)

- PCL:

  Pre-caudal length (mm)

- length:

  Preferred length measurement (STL)

- wgt:

  Weight (mm)

- sex:

  2 level factor, NA if unavailable

- umb_scar:

  Umbilical scar open? Yes, no or partially

- clasp_length:

  Outer length of male claspers (mm)

- clasp_calc:

  Were claspers calcified? Yes, no or partially

- gonad_stage:

  Macroscopic staging of male testes (Not used)

- run_sperm:

  Running sperm present? Yes, no or partially (Not used)

- MOD:

  Maximum diameter of the largest ovarian follicle

- yolky_ova:

  Number of yolky ovarian follices (Not used)

- uter_stage:

  Macroscopic staging of female uterus

- maturity_stage:

  Binary maturity stage: 0, immature; 1, mature

- maternity_stage:

  Binary female maternity stage: 0, non-maternal; 1, maternal

- emb:

  Number of embryos

- embTL:

  Mean total length of embryos

- embryo:

  Is individual an embryo? TRUE/FALSE

- male_emb:

  Number of male embryos

- female_emb:

  Number of female embryos

- vertebrae:

  Vertebrae collected? TRUE/FALSE

- age_agree:

  Consensus age estimate, adjusted for date of birth

## Source

<http://dx.doi.org/10.1071/MF12142>
