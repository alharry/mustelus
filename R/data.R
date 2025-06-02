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
#' western north Atlantic Ocean
#'
#' @format A data frame with 1087 rows and 4 variables:
#' \describe{
#'   \item{FL}{Fork length (mm)}
#'   \item{maturity_stage}{Binary maturity stage: 0, immature; 1, mature}
#'   \item{maternity_stage}{Binary maternity stage: 0, non-maternal; 1, maternal}
#'   \item{source}{Data source - see below url}
#' }
#' @source \url{http://dx.doi.org/10.1139/cjfas-2024-0031}
"sandbar"

