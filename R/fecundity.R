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
#' @param grouping_var Optional categorical grouping variable (e.g. region). Will be converted to a factor.
#' @param data A data frame containing the above variables
#' @return A nested tibble of class \code{"fecundity"} with one row per group,
#'   containing list columns \code{data}, \code{coefs}, \code{preds}, and \code{mods},
#'   each named by the grouping variable level.
#' @references Walker, T.I. (2005) Reproduction in fisheries science.
#'   In: Hamlett, W.C. (ed) \emph{Reproductive Biology and Phylogeny of Chondrichthyes}.
#' @examples
#' data(spottail)
#'
#' fec <- fecundity(emb, length, data = spottail)
#'
#' summary(fec)
#'
#' p <- plot(fec)
#'
#' p$Unspecified + xlab("Total length (mm)") + ylab("Number of embryos")
#' @export
fecundity <- function(fec, x, grouping_var = NULL, data) {
  # Bring in data
  new <- data |> transmute(x = {{ x }}, fec = {{ fec }})

  # If grouping_var is provided as an argument, add it to data
  grp_quo <- rlang::enquo(grouping_var)
  if (!rlang::quo_is_null(grp_quo)) {
    new$grouping_var <- as_factor(dplyr::pull(data, !!grp_quo))
    message(
      "The categorical variable ",
      rlang::as_label(grp_quo),
      " has ",
      nlevels(new$grouping_var),
      " levels."
    )
  } else {
    new$grouping_var <- factor("Unspecified")
  }

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

  # Drop groups too small to support a regression with intervals
  grp_n <- table(droplevels(new$grouping_var))
  too_small <- names(grp_n)[grp_n < 3]
  if (base::length(too_small) > 0) {
    warning(
      "Group(s) with fewer than 3 observations were dropped: ",
      paste(too_small, collapse = ", ")
    )
    new <- new[!(as.character(new$grouping_var) %in% too_small), ]
    new$grouping_var <- droplevels(new$grouping_var)
  }

  if (nrow(new) < 3) {
    stop("Fewer than 3 usable observations; cannot fit a regression.")
  }

  # If more than one level is present in 'grouping_var' create a new dataset with all data
  # and append to existing data
  if (base::length(levels(droplevels(new$grouping_var))) > 1) {
    new <- rbind(mutate(new, grouping_var = "all"), new)
  }

  # Function for modelling the fecundity relationship
  fecundity_mod <- function(data) {
    # Run model
    m <- lm(fec ~ x, data = data)
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
      mean.fec = signif(mean(data$fec), 3),
      fec.range = paste(min(data$fec), "-", max(data$fec)),
      x.range = paste(
        signif(min(data$x, na.rm = T), 4),
        "-",
        signif(max(data$x, na.rm = T), 4)
      )
    )

    # Predict over the observed range of gravid animals
    x_range <- with(
      data,
      seq(min(x, na.rm = T), max(x, na.rm = T), length.out = 200)
    )

    # Get mean, confidence and prediction intervals
    pred <- cbind(
      data.frame(x = x_range),
      predict(
        m,
        newdata = data.frame(x = x_range),
        interval = "confidence"
      )
    ) |>
      cbind(predict(
        m,
        newdata = data.frame(x = x_range),
        interval = "prediction"
      )[, -1])
    names(pred) <- c("x", "fec", "clower", "cupper", "plower", "pupper")

    # Save output
    out <- list(coefs = coefs, pred = pred, mod = m)
    return(out)
  }

  # Nest data into groups and run fecundity_mod function
  results <- new |>
    group_by(grouping_var) |>
    nest() |>
    mutate(
      .fit = map(data, fecundity_mod),
      coefs = map(.fit, "coefs"),
      preds = map(.fit, "pred"),
      mods = map(.fit, "mod")
    ) |>
    select(-.fit) |>
    mutate(across(c(data, coefs, preds, mods), ~ set_names(., grouping_var)))

  class(results) <- c("fecundity", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.fecundity <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.fecundity <- function(x, ...) {
  plot_lims <- x[which(x$grouping_var %in% c("all", "Unspecified")), ]

  fecundity_plots <- x |>
    group_split(grouping_var) |>
    map(
      ~ ggplot() +
        geom_ribbon(
          data = .$preds[[1]],
          aes(x = x, ymin = plower, ymax = pupper),
          col = "black",
          fill = "transparent",
          linetype = "dotted"
        ) +
        geom_ribbon(
          data = .$preds[[1]],
          aes(x = x, ymin = clower, ymax = cupper),
          col = "black",
          fill = "transparent",
          linetype = "dashed"
        ) +
        geom_line(data = .$preds[[1]], aes(x = x, y = fec)) +
        geom_point(data = .$data[[1]], aes(x = x, y = fec)) +
        geom_point(
          data = plot_lims$data[[1]],
          aes(x = x, y = fec),
          col = "transparent"
        ) +
        theme_classic()
    )

  names(fecundity_plots) <- x$grouping_var

  return(fecundity_plots)
}
