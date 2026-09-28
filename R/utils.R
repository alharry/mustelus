.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Welcome to \033[3mmustelus\033[0m package")
}

# Column names used in tidy evaluation and in list columns. Declared so that
# R CMD check does not report them as undefined global variables.
utils::globalVariables(c(
  ".fit", "age", "boot_coefs", "calc", "clasp", "clower", "coefs", "cupper",
  "fec", "len", "lower", "mat", "matern", "mod_b", "mods", "n", "plower",
  "preds", "pupper", "splits", "upper"
))
