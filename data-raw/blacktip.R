## Common blacktip shark data from Harry et al. (2019)
##
## Raw data and data validation steps are taken from the repository for the
## original paper, github.com/alharry/limbatus, pinned to the commit used for
## publication. Location data are omitted; the public spreadsheet contains
## dummy coordinates only.

library(readxl)
library(dplyr)

commit <- "c8e8ef3c6964e7a7c316684c843fa137013358c2"
url <- paste0("https://github.com/alharry/limbatus/raw/", commit,
              "/data/Data-dummy-lats-long.xlsx")
tmp <- tempfile(fileext = ".xlsx")
download.file(url, tmp, mode = "wb")

raw <- read_excel(tmp, sheet = "Data") |>
  filter(Species == "BTP")

blacktip <- raw |>
  # Data validation, as in analysis/query.R of the original repository
  filter(!Tag %in% "175") |> # Likely species ID error, no details other than length
  mutate(STL = ifelse(Tag %in% "189", 202, STL)) |>
  mutate(Clasp.length = ifelse(Tag %in% "19", 156, Clasp.length)) |>
  mutate(Clasp.length = ifelse(Tag %in% c("KH021208-2", "KH021208-8", "PM260508-3", "177",
                                          "BW110409-29", "BW110409-14", "BW120409-37", "48"),
                               NA, Clasp.length)) |> # Dubious clasper measurements
  filter(!Tag %in% "EB020609-9") |> # ID conflict, possible sample mixup
  mutate(Clasp.calc = ifelse(Tag %in% "DW240309-25", NA, Clasp.calc)) |>
  mutate(Clasp.calc = ifelse(Tag %in% "173", "y", Clasp.calc)) |>
  mutate(Clasp.calc = ifelse(Tag %in% c("66", "187", "46"), "n", Clasp.calc)) |>
  mutate(Uter.stage = ifelse(Tag %in% "PS120609-2", "C", Uter.stage)) |>
  mutate(Uter.stage = ifelse(Tag %in% "BW110410-18", "C", Uter.stage)) |>
  mutate(Uter.stage = ifelse(Tag %in% c("PS120509-2", "PS120509-4", "PS120509-5",
                                        "PS140509-6", "PS030609-10", "PS080609-9"),
                             "C", Uter.stage)) |>
  mutate(Clasp.length = ifelse(Tag %in% "608", NA, Clasp.length)) |>
  filter(!Tag %in% "178") |> # Noted as mature male, no corroborating evidence
  mutate(Uter.stage = ifelse(Tag %in% "PS120509-3", NA, Uter.stage)) |>
  # Assumed to be incorrectly aged. The original set only the consensus age to
  # missing; the readings are removed too so the fish is excluded consistently
  mutate(across(c(AgeAgree, Reader1, Reader2),
                \(x) ifelse(Tag %in% "BW290409-11", NA, x))) |>
  filter(!is.na(Sex)) |>

  # Maturity and maternity
  mutate(Clasp.calc = trimws(Clasp.calc)) |>
  mutate(Mat = ifelse(Uter.stage %in% c("A", "B") | Clasp.calc %in% c("n", "p"), 0, 1)) |>
  mutate(Mat = ifelse(is.na(Uter.stage) & is.na(Clasp.calc), NA, Mat)) |>
  mutate(Matern = ifelse(Uter.stage %in% c("D", "E", "F"), 1, 0)) |>
  mutate(Matern = ifelse(is.na(Uter.stage), NA, Matern)) |>

  # Partial ages, assuming a birth date of 1 November
  mutate(Month2 = ifelse(Month %in% 12, Month - 11, Month + 1)) |>
  mutate(across(c(Reader1, Reader2, AgeAgree), \(x) x + Month2 / 12)) |>

  # Embryo sex ratio, recorded as free text e.g. "3M 4F"
  mutate(male_emb = as.integer(stringr::str_match(Sex.Ratio.M.F, "(\\d+)M")[, 2]),
         female_emb = as.integer(stringr::str_match(Sex.Ratio.M.F, "(\\d+)F")[, 2]),
         female_emb = ifelse(!is.na(male_emb) & is.na(female_emb), 0L, female_emb)) |>

  transmute(
    source = factor(Source, levels = c("QLD2", "QLD", "NSW1", "NSW2"),
                    labels = c("QLD 2004-2007", "QLD 2007", "NSW 2008-2010", "NSW 2013")),
    date = as.Date(Date),
    month = as.integer(Month),
    year = as.integer(Year),
    tag = Tag,
    FL, STL, PCL,
    wgt = Wgt,
    sex = factor(casefold(Sex), levels = c("f", "m")),
    umb_scar = factor(Umb.Scar, levels = c("n", "p", "y")),
    neonate = Umb.Scar %in% c("y", "p"),
    clasp_length = Clasp.length,
    clasp_calc = factor(Clasp.calc, levels = c("n", "p", "y")),
    uter_stage = match(Uter.stage, LETTERS[1:6]),
    maturity_stage = as.integer(Mat),
    maternity_stage = as.integer(Matern),
    emb = as.integer(Emb),
    embTL = EmbTL,
    male_emb, female_emb,
    reader1 = Reader1,
    reader2 = Reader2,
    age_agree = AgeAgree
  ) |>
  as.data.frame()

usethis::use_data(blacktip, overwrite = TRUE)
