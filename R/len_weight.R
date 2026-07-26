#' Analyse weight-length relationship
#'
#' Function for running a log-linear regression model to analyse body mass as a function of length.
#' Essentially just a wrapper for \code{lm()} and \code{predict.lm()} that tabulates some useful
#' summary statistics. Also returns the predicted mean, 95 percent confidence intervals and prediction intervals,
#' corrected for bias due to log transformation, and the fitted \code{lm()} objects.
#' @param weight Numeric vector of weights
#' @param length Numeric vector of lengths
#' @param grouping_var Categorical variable containing two or more unique variables (e.g. sex). Will be converted into a factor.
#' @param data A data frame containing, minimally, variables for length and weight, and optionally sex
#' @return results A list containing the \code{lm} model, coefficients and other useful info, predicted mean and raw data
#' @examples
#' data(spottail)
#'
#' lw <- len_weight(wgt, length, sex, data = spottail)
#'
#' summary(lw)
#'
#' p <- plot(lw)
#'
#' p$f + xlab("Total Length (mm)") + ylab("Weight (kg)")
#' @export
len_weight <- function(weight, length, grouping_var = NULL, data) {
  # Load dependencies
  require(tidyverse)

  # Bring in data
  new <- data |> transmute(length = {{ length }}, weight = {{ weight }})

  # If grouping_var is provided as an argument, add it to data
  grp_quo <- rlang::enquo(grouping_var)
  if (!rlang::quo_is_null(grp_quo)) {
    new$grouping_var <- as_factor(dplyr::pull(data, !!grp_quo))
    message("The categorical variable ", rlang::as_label(grp_quo), " has ",
            nlevels(new$grouping_var), " levels.")
  } else {
    new$grouping_var <- factor("Unspecified")
  }

  # If more than one level is present in 'grouping_var' create a new dataset with all data
  # and append to existing data, remove missing values
  if (levels(droplevels(new$grouping_var)) |> length() > 1) {
    new |>
      mutate(new, grouping_var = c("all")) |>
      rbind(new) |>
      na.omit() -> new
  }


  # Function for modelling length weight relationship
  len_weight_mod <- function(data) {
    # Run model
    m <- lm(log(weight) ~ log(length), data = data)
    err <- sqrt(diag(vcov(m)))
    expon <- floor(log10(exp(coef(m)[1])))

    # Summary and coefficients
    coefs <- data.frame(
      a = signif(exp(coef(m)[1]), 4),
      Std.Error.range = paste("(", round(exp(coef(m)[1] - err[1]) / 10^expon, 3), "-", round(exp(coef(m)[1] + err[1]) / 10^expon, 3), ")"),
      b = signif(coef(m)[2], 4),
      Std.Error = paste("(", round(err[2], 3), ")"),
      Sigma = signif(summary(m)$sigma, 4),
      LL = signif(logLik(m)[1], 4),
      n = length(m$residuals),
      len.range = paste(min(data$length[which(data$weight > 0)], na.rm = T), "-", max(data$length[which(data$weight > 0)], na.rm = T))
    )
    len_range <- with(data, seq(min(length, na.rm = T), max(length, na.rm = T), 1))

    # Get mean, confidence and prediction intervals, adjusting for bias in log transform
    pred <- cbind(data.frame(length = len_range), exp(predict(m, newdata = data.frame(length = len_range), interval = "confidence") + summary(m)$sigma^2 / 2)) |>
      cbind(exp(predict(m, newdata = data.frame(length = len_range), interval = "prediction") + summary(m)$sigma^2 / 2)[, -1])
    names(pred) <- c("length", "weight", "clower", "cupper", "plower", "pupper")

    # Save output
    out <- list(coefs = coefs, pred = pred, mod = m)
    return(out)
  }

  # Nest data into groups and run len_weight_mod function
  results <- new |>
    group_by(grouping_var) |>
    nest() |>
    mutate(
      .fit  = map(data, len_weight_mod),
      coefs = map(.fit, "coefs"),
      preds = map(.fit, "pred"),
      mods  = map(.fit, "mod")
    ) |>
    select(-.fit) |>
    mutate(across(c(data, coefs, preds, mods), ~ set_names(., grouping_var)))

  class(results) <- c("len_weight", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.len_weight <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.len_weight <- function(x) {
  require(tidyverse)

  plot_lims <- x[which(x$grouping_var %in% c("all", "Unspecified")), ]

  len_weight_plots <- x |>
    group_split(grouping_var) |>
    map(~ ggplot() +
      geom_line(data = .$preds[[1]], aes(x = length, y = weight)) +
      geom_ribbon(data = .$preds[[1]], aes(x = length, ymin = clower, ymax = cupper), col = "black", fill = "transparent", linetype = "dashed") +
      geom_ribbon(data = .$preds[[1]], aes(x = length, ymin = plower, ymax = pupper), col = "black", fill = "transparent", linetype = "dotted") +
      geom_point(data = .$data[[1]], aes(x = length, y = weight)) +
      geom_point(data = plot_lims$data[[1]], aes(x = length, y = weight), col = "transparent") +
      theme_classic())

  names(len_weight_plots) <- x$grouping_var

  return(len_weight_plots)
}
