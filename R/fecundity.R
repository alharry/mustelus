#' Analyse fecundity as a function of length or age
#'
#' Fits a linear regression of fecundity (e.g. number of \emph{in utero} embryos)
#' against a continuous predictor such as length or age. Essentially a wrapper for
#' \code{lm()} and \code{predict.lm()} that tabulates useful summary statistics and
#' returns the predicted mean with 95 percent confidence and prediction intervals,
#' in the style of Walker (2005).
#'
#' Records with zero or negative fecundity are dropped before fitting, since a
#' count of zero indicates a non-gravid animal rather than a fecundity of zero.
#' The number dropped is reported as a message. Predictions therefore span the
#' length or age range of gravid animals only.
#'
#' @param fec Numeric vector of fecundity counts (e.g. number of embryos)
#' @param x Continuous predictor variable (e.g. length, age)
#' @param data A data frame containing the above variables
#' @return A one row tibble of class \code{"fecundity"} containing the list
#'   columns \code{data}, \code{coefs}, \code{preds}, and \code{mods}.
#' @references Walker, T.I. (2005) Reproduction in fisheries science.
#'   In: Hamlett, W.C. (ed) \emph{Reproductive Biology and Phylogeny of Chondrichthyes}.
#' @examples
#' data(spottail)
#'
#' fec <- fecundity(emb, length, data = spottail)
#'
#' summary(fec)
#'
#' plot(fec) + xlab("Total length (mm)") + ylab("Number of embryos")
#' @export
fecundity <- function(fec, x, data) {
  # Bring in data
  new <- data |> transmute(x = {{ x }}, fec = {{ fec }})

  new <- new[!is.na(new$x) & !is.na(new$fec), ]

  # Drop non-gravid records: a count of zero is not a fecundity observation
  n_zero <- sum(new$fec <= 0)
  if (n_zero > 0) {
    message(
      n_zero,
      " record(s) with zero or negative fecundity were dropped before fitting."
    )
    new <- new[new$fec > 0, ]
  }

  if (nrow(new) < 3) {
    stop("Fewer than 3 usable observations; cannot fit a regression.")
  }

  # Run model
  m <- lm(fec ~ x, data = new)
  s <- summary(m)
  err <- sqrt(diag(vcov(m)))

  # Summary and coefficients
  coefs <- data.frame(
    a = signif(coef(m)[1], 4),
    a.Std.Error = paste("(", signif(err[1], 3), ")"),
    b = signif(coef(m)[2], 4),
    b.Std.Error = paste("(", signif(err[2], 3), ")"),
    r.squared = signif(s$r.squared, 3),
    p.value = signif(coef(s)[2, 4], 3),
    Sigma = signif(s$sigma, 4),
    n = base::length(m$residuals),
    mean.fec = signif(mean(new$fec), 3),
    fec.range = paste(min(new$fec), "-", max(new$fec)),
    x.range = paste(
      signif(min(new$x, na.rm = T), 4),
      "-",
      signif(max(new$x, na.rm = T), 4)
    )
  )

  # Predict over the observed range of gravid animals
  x_range <- with(
    new,
    seq(min(x, na.rm = T), max(x, na.rm = T), length.out = 200)
  )

  # Get mean, confidence and prediction intervals
  pred <- cbind(
    data.frame(x = x_range),
    predict(m, newdata = data.frame(x = x_range), interval = "confidence")
  ) |>
    cbind(predict(
      m,
      newdata = data.frame(x = x_range),
      interval = "prediction"
    )[, -1])
  names(pred) <- c("x", "fec", "clower", "cupper", "plower", "pupper")

  results <- tibble(
    data = list(new),
    coefs = list(coefs),
    preds = list(pred),
    mods = list(m)
  )

  class(results) <- c("fecundity", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.fecundity <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.fecundity <- function(x, ...) {
  pred <- x$preds[[1]]
  raw <- x$data[[1]]

  ggplot() +
    geom_ribbon(
      data = pred,
      aes(x = x, ymin = plower, ymax = pupper),
      col = "black",
      fill = "transparent",
      linetype = "dotted"
    ) +
    geom_ribbon(
      data = pred,
      aes(x = x, ymin = clower, ymax = cupper),
      col = "black",
      fill = "transparent",
      linetype = "dashed"
    ) +
    geom_line(data = pred, aes(x = x, y = fec)) +
    geom_point(data = raw, aes(x = x, y = fec)) +
    theme_classic()
}
