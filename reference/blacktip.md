# Common blacktip shark data

A dataset containing life history information for 475 common blacktip
sharks, *Carcharhinus limbatus*, collected from south-east Queensland
and northern New South Wales, Australia, between 2004 and 2013. These
are the data analysed by Harry et al. (2019), including the corrections
made in that study.

## Usage

``` r
blacktip
```

## Format

A data frame with 475 rows and 24 variables:

- source:

  Data source: `"QLD 2004-2007"`, Moreton Bay survey; `"QLD 2007"`,
  neonates purchased from a Moreton Bay commercial fisher;
  `"NSW 2008-2010"` and `"NSW 2013"`, observer surveys of the New South
  Wales Ocean Trap and Line Fishery

- date:

  Date collected

- month:

  Month, integer form

- year:

  Calendar year

- tag:

  Identification number

- FL:

  Fork length (cm)

- STL:

  Stretched total length (cm), measured with the upper caudal lobe
  depressed in line with the body axis

- PCL:

  Pre-caudal length (cm)

- wgt:

  Weight (kg)

- sex:

  2 level factor

- umb_scar:

  Umbilical scar open? Yes, no or partially

- neonate:

  Known age-zero individual, `TRUE` where the umbilical scar was open or
  partially healed

- clasp_length:

  Outer length of male claspers (mm)

- clasp_calc:

  Were claspers calcified? Yes, no or partially

- uter_stage:

  Macroscopic staging of female uterus, 1 to 6 (recorded as A to F in
  the original data)

- maturity_stage:

  Binary maturity stage: 0, immature; 1, mature

- maternity_stage:

  Binary female maternity stage: 0, non-maternal; 1, maternal

- emb:

  Number of embryos

- embTL:

  Mean total length of embryos (mm)

- male_emb:

  Number of male embryos

- female_emb:

  Number of female embryos

- reader1:

  Age from the first reader, adjusted for date of birth

- reader2:

  Age from the second reader, adjusted for date of birth

- age_agree:

  Consensus age estimate, adjusted for date of birth

## Source

<https://github.com/alharry/limbatus>

## Details

The data combine four sources that used different fishing gears and
sampled different parts of the population. Sharks from Moreton Bay,
Queensland, were mostly neonates and small juveniles, sampled by
fishery-independent methods and by a commercial gillnet fisher. Sharks
from New South Wales were mostly larger than 150 cm and were caught on
demersal setlines by the Ocean Trap and Line Fishery. Vertebrae were
collected only from the 2008 to 2010 New South Wales survey, and
umbilical scars were recorded only in Queensland. Species identity in
the 2008 to 2010 survey was determined genetically, and individuals of
hybrid ancestry with *C. tilstoni* are included, as in the original
study.

Ages are counts of growth zone pairs on sectioned vertebrae, read
independently by two readers, plus the fraction of a year between an
assumed birth date of 1 November and the start of the month of capture.
The same fraction is added to both readings and the consensus age, so
they can be passed directly to
[`growth()`](https://alharry.github.io/mustelus/reference/growth.md).

## References

Harry, A.V., Butcher, P.A., Macbeth, W.G., Morgan, J.A.T., Taylor, S.M.
and Geraghty, P.T. (2019) Life history of the common blacktip shark,
*Carcharhinus limbatus*, from central eastern Australia and comparative
demography of a cryptic shark complex. *Marine and Freshwater Research*
**70**(6), 834-848.
[doi:10.1071/MF18141](https://doi.org/10.1071/MF18141)
