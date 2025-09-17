library(plyr)

#create a linear regression litter number (emb) ~ length 
#ln(p)=a+bl

#create linear regression model
length_litter <- function(litter, length, grouping_var = NULL, data) {
  # Load dependencies
  require(tidyverse)
  
  # Bring in data
  arguments <- as.list(match.call())
  new <- tibble(length = eval(arguments$length, data), litter = eval(arguments$litter, data))
  
  # If grouping_var is provided as an argument, add it to data
  if (!is.null(arguments$grouping_var)) {
    new$grouping_var <- as_factor(eval(arguments$grouping_var, data))
    print(paste0("The categorical variable ", arguments$grouping_var, " has ", length(levels(as.factor(new$grouping_var))), " levels."))
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
  # Function for modelling length litter relationship
  length_litter_mod <- function(data) {
    # Run model
    m <- lm(litter ~ length, data = data)
    #err returns variance-covariance matrix of m
    err <- sqrt(diag(vcov(m)))
    #expon numeric vector containing largest integers not greater than log10(expected coeff of m)
    expon <- floor(log10(exp(coef(m)[1])))
    
    # Summary and coefficients rounded to 4 sig fig
    coefs <- data.frame(
      a = signif(coef(m)[1], 4),
      Std.Error.range = paste("(", round((coef(m)[1] - err[1]) / 10^expon, 3), "-", round((coef(m)[1] + err[1]) / 10^expon, 3), ")"),
      b = signif(coef(m)[2], 4),
      Std.Error = paste("(", round(err[2], 3), ")"),
      Sigma = signif(summary(m)$sigma, 4),
      LL = signif(logLik(m)[1], 4),
      n = length(m$residuals),
      #length range is min length - max length
      len.range = paste(min(data$length[which(data$litter > 0)], na.rm = T), "-", max(data$length[which(data$litter > 0)], na.rm = T))
    )
    len_range <- with(data, seq(min(length, na.rm = T), max(length, na.rm = T), 1))
    
    # Get mean, confidence and prediction intervals, adjusting for bias in log transform
    #cbind combines length range+exponential(m)+confidence interval
    pred <- cbind(data.frame(length = len_range), (predict(m, newdata = data.frame(length = len_range), interval = "confidence") + summary(m)$sigma^2 / 2)) |>
      cbind((predict(m, newdata = data.frame(length = len_range), interval = "prediction") + summary(m)$sigma^2 / 2)[, -1])
    #clower/ cupper= confidence lower/upper and plower/pupper = predicted m lower/upper
    names(pred) <- c("length", "litter", "clower", "cupper", "plower", "pupper")
    
    # Save output
    out <- list(coefs = coefs, pred = pred, mod = m)
    return(out)
  }
  
  # Nest data into groups and run length_litter_mod function
  results <- new |>
    group_by(grouping_var) |>
    nest() |>
    mutate(coefs = map(data, ~ length_litter_mod(.)$coefs)) |>
    mutate(preds = map(data, ~ length_litter_mod(.)$pred)) |>
    mutate(mods = map(data, ~ length_litter_mod(.)$mod))
  
  class(results) <- c("length_litter", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.length_litter <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.length_litter <- function(x) {
  require(tidyverse)
  
  plot_lims <- x[which(ll$grouping_var %in% c("all", "Unspecified")), ]
  
  length_litter_plots <- x |>
    group_split(grouping_var) |>
    map(~ ggplot() +
          geom_line(data = .$preds[[1]], aes(x = length, y = litter)) +
          #dashed line is 95% confidence interval
          geom_ribbon(data = .$preds[[1]], aes(x = length, ymin = clower, ymax = cupper), col = "black", fill = "transparent", linetype = "dashed") +
          #dotted line is predicted interval
          geom_ribbon(data = .$preds[[1]], aes(x = length, ymin = plower, ymax = pupper), col = "black", fill = "transparent", linetype = "dotted") +
          geom_point(data = .$data[[1]], aes(x = length, y = litter)) +
          geom_point(data = plot_lims$data[[1]], aes(x = length, y = litter), col = "transparent") +
          theme_classic())
  
  names(length_litter_plots) <- ll$grouping_var
  
  return(length_litter_plots)
}

#test it using spottail data
load('spottail.rda')

#'
ll <- length_litter(emb, length, sex, data = spottail)
#'
summary(ll)
#'
p2 <- plot(ll)
#'
p2$f + xlab("Total Length (mm)") + ylab("Litter size")


