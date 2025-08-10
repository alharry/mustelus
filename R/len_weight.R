#' Analyse weight-length relationship
#' 
#' Function for running a log-linear regression model to analyse body mass as a function of length. 
#' Essentially just a wrapper for \code{lm()} and \code{predict.lm()} that tabulates some useful 
#' summary statistics. Also returns the predicted mean, 95 percent confidence intervals and prediction intervals, 
#' corrected for bias due to log transformation, and the fitted \code{lm()} objects. 
#' @param Weight Numeric vector of weights
#' @param Length Numeric vector of lengths
#' @param Sex Factor containing two levels
#' @param data A data frame containing, minimally, variables for length and weight, and optionally sex
#' @return results A list containing the \code{lm} model, coefficients and other useful info, predicted mean and raw data
#' @examples
#' data(spottail)
#' 
#' lw <- len_weight(wgt, length, sex, data = spottail)
#' 
#' summary(lw)
#' 
#' p <- plot(lw, log = T)
#' 
#' p$f + xlab("ln Total Length (mm)") + ylab("ln Weight (kg)") + facet_null()
#' @export
len_weight <- function(Weight, Length, Sex = NULL, data) {
  # Load dependencies
  require(dplyr)
  require(plyr)

  # Bring in data
  arguments <- as.list(match.call())
  new <- tibble(Weight = eval(arguments$Weight, data), Length = eval(arguments$Length, data))

# If sex is provided as an argument, add it to data
if (!is.null(arguments$Sex)) {
  new$Sex <- eval(arguments$Sex, data)
} else {
  new$Sex <- factor("Unspecified")
}
  # If more than one level is present in 'sex' create a new dataset with all data
  # and append to existing data, remove missing values
  if (droplevels(new$Sex) |> levels() |> length() > 1) {
    new2 <- mutate(new, Sex = "all") |> na.omit()
    new <- rbind(new, new2) |> na.omit()
  } else {
    new <- na.omit(new)
  }

# Check function inputs
if (!is.factor(new$Sex)) {
  stop("Sex should be a factor")
}

  # Function for modelling length weight relationship
  len_weight_mod <- function(data) {
    # Run model
    m <- lm(log(Weight) ~ log(Length), data = data)
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
      len.range = paste(min(data$Length[which(data$Weight > 0)], na.rm = T), "-", max(data$Length[which(data$Weight > 0)], na.rm = T))
    )
    len_range <- with(data, seq(min(Length, na.rm = T), max(Length, na.rm = T), 1))

    # Get mean, confidence and prediction intervals, adjusting for bias in log transform
    pred <- cbind(data.frame(Length = len_range), exp(predict(m, newdata = data.frame(Length = len_range), interval = "confidence") + summary(m)$sigma^2 / 2)) |>
      cbind(exp(predict(m, newdata = data.frame(Length = len_range), interval = "prediction") + summary(m)$sigma^2 / 2)[,-1])
    names(pred) <- c("length", "wgt", "clower", "cupper", "plower", "pupper")

    # Save output
    out <- list(coefs = coefs, pred = pred, mod = m)
    return(out)
  }

  # Need something to determine what to give to dlply
  out <- dlply(new, .(Sex), len_weight_mod)
  coefs <- ldply(out, function(x) {
    x$coef
  })
  preds <- ldply(out, function(x) {
    x$pred
  })
  mods <- llply(out, function(x) {
    x$mod
  })

  results <- list(coefs = coefs, preds = preds, mods = mods, data = new)
  class(results) <- "len_weight"

  return(invisible(results))
}

plot.len_weight <- function(x, log = F, display = T, ...) {
  require(ggplot2)

  pred <- x$preds
  data <- x$data
  plots <- list()
  logplots <- list()

  ## Plots
  # Normal space
  for (i in levels(pred$Sex)) {
    p <- ggplot(filter(pred, Sex %in% i), aes(x = length, y = wgt)) +
      geom_line() +
      geom_line(aes(y = cupper), linetype = "dashed") +
      geom_line(aes(y = clower), linetype = "dashed") +
      geom_line(aes(y = pupper), linetype = "dotted") +
      geom_line(aes(y = plower), linetype = "dotted") +
      geom_point(data = filter(data, Sex %in% i), aes(x = Length, y = Weight)) +
      xlab("Length") +
      ylab("Weight") +
      facet_wrap(~Sex)
    plots[[i]] <- p
    # In log space
    p1 <- ggplot(filter(pred, Sex %in% i), aes(x = log(length), y = log(wgt))) +
      geom_line() +
      geom_line(aes(y = log(cupper)), linetype = "dashed") +
      geom_line(aes(y = log(clower)), linetype = "dashed") +
      geom_line(aes(y = log(pupper)), linetype = "dotted") +
      geom_line(aes(y = log(plower)), linetype = "dotted") +
      geom_point(data = filter(data, Sex %in% i), aes(x = log(Length), y = log(Weight))) +
      xlab("ln length") +
      ylab("ln weight") +
      facet_wrap(~Sex)
    logplots[[i]] <- p1
    if (display == T) {
      if (log == F) {
        par(ask = T)
        plot(p)
      } else {
        plot(p1)
      }
      flush.console()
    }
  }
  par(ask = F)

  if (log == F) {
    return(plots = invisible(plots))
  } else {
    return(plots = invisible(logplots))
  }
}

summary.len_weight <- function(x) {
  print(x$coefs)
}