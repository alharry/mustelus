#' Spot-tail shark data
#' 
#' A dataset containing life history information for 659 spot-tail sharks,
#' \emph{Carcharhinus sorrah}, collected from north-eastern Australia.
#'
#' @format A data frame with 659 rows and 27 variables:
#' \describe{
#'   \item{month}{Month, integer form}
#'   \item{year}{Calendar year}
#'   \item{date}{Date collected}
#'   \item{jday}{Day of year}
#'   \item{tag}{Identification number}
#'   \item{FL}{Fork length (mm)}
#'   \item{TL}{Total length (mm)}
#'   \item{PCL}{Pre-caudal length (mm)}
#'   \item{length}{Preferred length measurement (STL)}
#'   \item{wgt}{Weight (mm)}
#'   \item{sex}{2 level factor, NA if unavailable}
#'   \item{umb_scar}{Umbilical scar open? Yes, no or partially}
#'   \item{clasp_length}{Outer length of male claspers (mm)}
#'   \item{clasp_calc}{Were claspers calcified? Yes, no or partially}
#'   \item{gonad_stage}{Macroscopic staging of male testes (Not used)}
#'   \item{run_sperm}{Running sperm present? Yes, no or partially (Not used)}
#'   \item{MOD}{Maximum diameter of the largest ovarian follicle}
#'   \item{yolky_ova}{Number of yolky ovarian follices (Not used)}
#'   \item{uter_stage}{Macroscopic staging of female uterus}
#'   \item{maturity_stage}{Binary maturity stage: 0, immature; 1, mature}
#'   \item{maternity_stage}{Binary female maternity stage: 0, non-maternal; 1, maternal}
#'   \item{emb}{Number of embryos}
#'   \item{embTL}{Mean total length of embryos}
#'   \item{embryo}{Is individual an embryo? TRUE/FALSE}
#'   \item{male_emb}{Number of male embryos}
#'   \item{female_emb}{Number of female embryos}
#'   \item{vertebrae}{Vertebrae collected? TRUE/FALSE}
#'   \item{age_agree}{Consensus age estimate, adjusted for date of birth}
#' }
#' @source \url{http://dx.doi.org/10.1071/MF12142}
"spottail"

#' Sandbar shark data
#'
#' A dataset containing maturity and maternity data from 1087 female sandbar
#' sharks, \emph{Carcharhinus plumbeus}, collected from the Gulf of Mexico and
#' western north Atlantic Ocean. Data from two studies were combined and
#' maternal condition assigned to each individual for the empirical case study
#' of Harry et al. (2024).
#'
#' @format A data frame with 1087 rows and 4 variables:
#' \describe{
#'   \item{FL}{Fork length (cm)}
#'   \item{maturity_stage}{Binary maturity stage: 0, immature; 1, mature}
#'   \item{maternity_stage}{Binary maternity stage: 0, non-maternal; 1, maternal}
#'   \item{source}{Originating study: \code{"Baremore"} or \code{"Piercy"}}
#' }
#' @references
#' Baremore, I.E. and Hale, L.F. (2012) Reproduction of the sandbar shark in the
#' western North Atlantic Ocean and Gulf of Mexico. \emph{Marine and Coastal
#' Fisheries} \strong{4}(1), 560-572. \doi{10.1080/19425120.2012.700904}
#'
#' Harry, A.V., Baremore, I.E. and Piercy, A.N. (2024) Quantifying maternal
#' reproductive output of chondrichthyan fishes. \emph{Canadian Journal of
#' Fisheries and Aquatic Sciences} \strong{81}(10), 1481-1494.
#' \doi{10.1139/cjfas-2024-0031}
#'
#' Piercy, A.N., Murie, D.J. and Gelsleichter, J.J. (2016) Histological and
#' morphological aspects of reproduction in the sandbar shark
#' \emph{Carcharhinus plumbeus} in the U.S. south-eastern Atlantic Ocean and
#' Gulf of Mexico. \emph{Journal of Fish Biology} \strong{88}(5), 1708-1730.
#' \doi{10.1111/jfb.12945}
#' @source \url{https://doi.org/10.1139/cjfas-2024-0031}
"sandbar"

#' Common blacktip shark data
#'
#' A dataset containing life history information for 475 common blacktip
#' sharks, \emph{Carcharhinus limbatus}, collected from south-east Queensland
#' and northern New South Wales, Australia, between 2004 and 2013. These are
#' the data analysed by Harry et al. (2019), including the corrections made in
#' that study.
#'
#' The data combine four sources that used different fishing gears and
#' sampled different parts of the population. Sharks from Moreton Bay,
#' Queensland, were mostly neonates and small juveniles, sampled by
#' fishery-independent methods and by a commercial gillnet fisher. Sharks from New South
#' Wales were mostly larger than 150 cm and were caught on demersal setlines by
#' the Ocean Trap and Line Fishery. Vertebrae were collected only from the
#' 2008 to 2010 New South Wales survey, and umbilical scars were recorded only
#' in Queensland. Species identity in the 2008 to 2010 survey was determined
#' genetically, and individuals of hybrid ancestry with \emph{C. tilstoni} are
#' included, as in the original study.
#'
#' Ages are counts of growth zone pairs on sectioned vertebrae, read
#' independently by two readers, plus the fraction of a year between an
#' assumed birth date of 1 November and the start of the month of capture.
#' The same fraction is added to both readings and the consensus age, so they
#' can be passed directly to \code{growth()}.
#'
#' @format A data frame with 475 rows and 24 variables:
#' \describe{
#'   \item{source}{Data source: \code{"QLD 2004-2007"}, Moreton Bay survey;
#'     \code{"QLD 2007"}, neonates purchased from a Moreton Bay commercial
#'     fisher; \code{"NSW 2008-2010"} and \code{"NSW 2013"}, observer surveys
#'     of the New South Wales Ocean Trap and Line Fishery}
#'   \item{date}{Date collected}
#'   \item{month}{Month, integer form}
#'   \item{year}{Calendar year}
#'   \item{tag}{Identification number}
#'   \item{FL}{Fork length (cm)}
#'   \item{STL}{Stretched total length (cm), measured with the upper caudal
#'     lobe depressed in line with the body axis}
#'   \item{PCL}{Pre-caudal length (cm)}
#'   \item{wgt}{Weight (kg)}
#'   \item{sex}{2 level factor}
#'   \item{umb_scar}{Umbilical scar open? Yes, no or partially}
#'   \item{neonate}{Known age-zero individual, \code{TRUE} where the umbilical
#'     scar was open or partially healed}
#'   \item{clasp_length}{Outer length of male claspers (mm)}
#'   \item{clasp_calc}{Were claspers calcified? Yes, no or partially}
#'   \item{uter_stage}{Macroscopic staging of female uterus, 1 to 6 (recorded
#'     as A to F in the original data)}
#'   \item{maturity_stage}{Binary maturity stage: 0, immature; 1, mature}
#'   \item{maternity_stage}{Binary female maternity stage: 0, non-maternal; 1,
#'     maternal}
#'   \item{emb}{Number of embryos}
#'   \item{embTL}{Mean total length of embryos (mm)}
#'   \item{male_emb}{Number of male embryos}
#'   \item{female_emb}{Number of female embryos}
#'   \item{reader1}{Age from the first reader, adjusted for date of birth}
#'   \item{reader2}{Age from the second reader, adjusted for date of birth}
#'   \item{age_agree}{Consensus age estimate, adjusted for date of birth}
#' }
#' @references
#' Harry, A.V., Butcher, P.A., Macbeth, W.G., Morgan, J.A.T., Taylor, S.M. and
#' Geraghty, P.T. (2019) Life history of the common blacktip shark,
#' \emph{Carcharhinus limbatus}, from central eastern Australia and comparative
#' demography of a cryptic shark complex. \emph{Marine and Freshwater Research}
#' \strong{70}(6), 834-848. \doi{10.1071/MF18141}
#' @source \url{https://github.com/alharry/limbatus}
"blacktip"

