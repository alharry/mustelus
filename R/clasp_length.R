#' Fill colours for the conventional clasper calcification coding
#'
#' Not calcified, partially calcified and calcified, shaded from white through
#' grey to black.
#' @noRd
calc_cols <- c(n = "white", p = "grey65", y = "black")

#' Logistic curve describing clasper elongation
#'
#' Internal helper giving clasper length as a logistic function of body length
#' or age, parameterised so that \code{L50} and \code{L95} are the values of
#' \code{x} at which clasper length reaches 50 and 95 percent of the way from
#' the juvenile asymptote \code{b} to the adult asymptote \code{a}.
#' @param x Continuous predictor (length or age)
#' @param a Adult (upper) asymptote
#' @param b Juvenile (lower) asymptote
#' @param L50 Value of \code{x} at 50 percent of clasper elongation
#' @param L95 Value of \code{x} at 95 percent of clasper elongation
#' @noRd
clasp_curve <- function(x, a, b, L50, L95) {
  b + (a - b) / (1 + exp(-log(19) * (x - L50) / (L95 - L50)))
}

#' Derive starting values for the clasper elongation model
#'
#' Estimates asymptotes from the tails of the observed clasper lengths, then
#' interpolates the predictor values at which binned means cross the 50 and 95
#' percent elongation points.
#' @param d Data frame with columns \code{x} and \code{clasp}
#' @noRd
clasp_start <- function(d) {
  # Asymptotes from the smallest and largest animals, rather than from the tails
  # of the clasper lengths themselves, which are sensitive to outliers
  xq <- quantile(d$x, c(0.2, 0.8))
  b0 <- mean(d$clasp[d$x <= xq[1]])
  a0 <- mean(d$clasp[d$x >= xq[2]])
  if (!is.finite(b0) || b0 <= 0) b0 <- min(d$clasp)
  if (!is.finite(a0) || a0 <= b0) a0 <- max(d$clasp)

  br <- seq(min(d$x), max(d$x), length.out = 21)
  bin <- cut(d$x, br, include.lowest = TRUE)
  mx <- tapply(d$x, bin, mean)
  my <- tapply(d$clasp, bin, mean)
  ok <- !is.na(mx) & !is.na(my)
  mx <- mx[ok]
  my <- cummax(my[ok])

  L50_0 <- approx(my, mx, xout = b0 + 0.50 * (a0 - b0), ties = "ordered", rule = 2)$y
  L95_0 <- approx(my, mx, xout = b0 + 0.95 * (a0 - b0), ties = "ordered", rule = 2)$y
  if (!is.finite(L95_0) || L95_0 <= L50_0) {
    L95_0 <- L50_0 + 0.15 * diff(range(d$x))
  }

  list(a = a0, b = b0, L50 = L50_0, L95 = L95_0)
}

#' Analyse clasper length as a function of length or age
#'
#' Fits a nonlinear (logistic) model of clasper length against a continuous
#' predictor such as body length or age, describing the rapid elongation of
#' claspers that accompanies maturation in male chondrichthyans. The model is
#'
#' \deqn{CL = b + (a - b)\left(1 + e^{-\log(19)(x - L_{50})/(L_{95} - L_{50})}\right)^{-1}}
#'
#' where \code{b} and \code{a} are the juvenile and adult asymptotes, and
#' \code{L50} and \code{L95} are the values of the predictor at which clasper
#' length reaches 50 and 95 percent of the way between them. It is fitted on the
#' log scale via \code{nls()}, giving multiplicative error, so the fitted curve
#' describes median rather than mean clasper length.
#'
#' Confidence intervals on the parameters and on the fitted curve are obtained by
#' bootstrap resampling with \code{rsample}. Prediction intervals combine the
#' bootstrap variance of the curve with the residual variance of the fit.
#'
#' Records with missing or non-positive clasper length are dropped, so passing a
#' data frame containing both sexes is safe provided females are recorded as
#' \code{NA}.
#'
#' @param clasp Numeric vector of clasper lengths
#' @param x Continuous predictor variable (e.g. length, age)
#' @param calc Optional clasper calcification stage, conventionally coded
#'   \code{"n"} (not calcified), \code{"p"} (partially calcified) and \code{"y"}
#'   (calcified). Used only for plotting, where points are shaded white, grey and
#'   black respectively; it does not enter the model.
#' @param data A data frame containing the above variables
#' @param times Number of bootstrap replicates (default 1000)
#' @param start Optional named list of starting values for \code{a}, \code{b},
#'   \code{L50} and \code{L95}. If \code{NULL} (the default) these are derived
#'   from the data.
#' @return A one row tibble of class \code{"clasp_length"} containing the list
#'   columns \code{data}, \code{coefs}, \code{preds}, \code{mods} and
#'   \code{boot_coefs}.
#' @examples
#' data(spottail)
#'
#' cl <- clasp_length(clasp_length, length, clasp_calc, data = spottail, times = 200)
#'
#' summary(cl)
#'
#' plot(cl) + xlab("Total length (mm)") + ylab("Clasper length (mm)")
#' @export
clasp_length <- function(clasp, x, calc = NULL, data, times = 1000, start = NULL) {
  # Bring in data
  new <- data |> transmute(x = {{ x }}, clasp = {{ clasp }})

  # Calcification stage is carried through for plotting only
  calc_quo <- rlang::enquo(calc)
  if (!rlang::quo_is_null(calc_quo)) {
    new$calc <- as_factor(dplyr::pull(data, !!calc_quo))
    # Put the conventional n/p/y coding in developmental order
    if (all(levels(new$calc) %in% names(calc_cols))) {
      new$calc <- factor(
        as.character(new$calc),
        levels = names(calc_cols)[names(calc_cols) %in% levels(new$calc)]
      )
    }
    message(
      "The calcification variable ",
      rlang::as_label(calc_quo),
      " has ",
      nlevels(new$calc),
      " levels."
    )
  }

  new <- new[!is.na(new$x) & !is.na(new$clasp), ]

  # Clasper length is log transformed, so non-positive values cannot be used
  n_invalid <- sum(new$clasp <= 0)
  if (n_invalid > 0) {
    message(
      n_invalid,
      " record(s) with zero or negative clasper length were dropped before fitting."
    )
    new <- new[new$clasp > 0, ]
  }

  if (nrow(new) < 5) {
    stop("Fewer than 5 usable observations; cannot fit the model.")
  }

  # Starting values
  if (is.null(start)) start <- clasp_start(new)

  # The 'port' algorithm keeps both asymptotes positive, which the default
  # algorithm does not, and log() of a negative asymptote aborts the fit
  clasp_fit <- function(d) {
    nls(
      log(clasp) ~ log(clasp_curve(x, a, b, L50, L95)),
      data = d,
      start = start[c("a", "b", "L50", "L95")],
      algorithm = "port",
      lower = c(a = 1e-8, b = 1e-8, L50 = -Inf, L95 = -Inf),
      control = nls.control(maxiter = 200)
    )
  }

  m <- try(clasp_fit(new), silent = TRUE)
  if (inherits(m, "try-error")) {
    stop(
      "Model failed to converge. Try supplying starting values via 'start', ",
      "e.g. start = list(a = , b = , L50 = , L95 = ).\n  ",
      attr(m, "condition")$message
    )
  }
  cf <- coef(m)
  sigma <- summary(m)$sigma

  # Bootstrap resamples; nls may fail to converge on some, so these are dropped
  boot_splits <- rsample::bootstraps(new, times = times)
  boot_mods <- boot_splits$splits |>
    map(~ try(clasp_fit(rsample::analysis(.x)), silent = TRUE))
  converged <- !map_lgl(boot_mods, ~ inherits(.x, "try-error"))

  if (sum(converged) < 2) {
    stop("Bootstrap failed to converge; try supplying 'start' values.")
  }
  if (any(!converged)) {
    message(
      sum(!converged),
      " of ",
      times,
      " bootstrap replicates failed to converge and were dropped."
    )
  }
  boot_mods <- boot_mods[converged]

  boot_coefs <- boot_mods |>
    map(~ as.data.frame(t(coef(.x)))) |>
    reduce(rbind)

  # Predict over the observed range of the predictor
  x_range <- seq(min(new$x), max(new$x), length.out = 200)

  # Curve from each bootstrap replicate, on the log scale
  boot_log <- boot_coefs |>
    nrow() |>
    seq_len() |>
    map(~ log(clasp_curve(
      x_range,
      boot_coefs$a[.x],
      boot_coefs$b[.x],
      boot_coefs$L50[.x],
      boot_coefs$L95[.x]
    ))) |>
    reduce(cbind)

  fit_log <- log(clasp_curve(x_range, cf[["a"]], cf[["b"]], cf[["L50"]], cf[["L95"]]))

  # Confidence interval from the bootstrap; prediction interval adds residual variance
  clower <- exp(apply(boot_log, 1, quantile, 0.025))
  cupper <- exp(apply(boot_log, 1, quantile, 0.975))
  se_fit <- sqrt(apply(boot_log, 1, var) + sigma^2)
  plower <- exp(fit_log - qnorm(0.975) * se_fit)
  pupper <- exp(fit_log + qnorm(0.975) * se_fit)

  pred <- data.frame(
    x = x_range,
    clasp = exp(fit_log),
    clower = clower,
    cupper = cupper,
    plower = plower,
    pupper = pupper
  )

  # Summary and coefficients
  ci <- function(p) signif(quantile(boot_coefs[[p]], c(0.025, 0.975)), 4)
  coefs <- data.frame(
    a = signif(cf[["a"]], 4),
    a_lower = ci("a")[1],
    a_upper = ci("a")[2],
    b = signif(cf[["b"]], 4),
    b_lower = ci("b")[1],
    b_upper = ci("b")[2],
    L50 = signif(cf[["L50"]], 4),
    L50_lower = ci("L50")[1],
    L50_upper = ci("L50")[2],
    L95 = signif(cf[["L95"]], 4),
    L95_lower = ci("L95")[1],
    L95_upper = ci("L95")[2],
    Sigma = signif(sigma, 4),
    n = nrow(new),
    x.range = paste(signif(min(new$x), 4), "-", signif(max(new$x), 4))
  )
  rownames(coefs) <- NULL

  results <- tibble(
    data = list(new),
    coefs = list(coefs),
    preds = list(pred),
    mods = list(m),
    boot_coefs = list(boot_coefs)
  )

  class(results) <- c("clasp_length", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.clasp_length <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.clasp_length <- function(x, ...) {
  pred <- x$preds[[1]]
  raw <- x$data[[1]]

  p <- ggplot() +
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
    geom_line(data = pred, aes(x = x, y = clasp))

  if ("calc" %in% names(raw)) {
    lv <- levels(raw$calc)
    # Use the n/p/y shading where it applies, otherwise an even grey ramp
    cols <- if (all(lv %in% names(calc_cols))) {
      calc_cols[lv]
    } else {
      set_names(gray.colors(base::length(lv), start = 1, end = 0), lv)
    }
    p <- p +
      geom_point(
        data = raw,
        aes(x = x, y = clasp, fill = calc),
        shape = 21,
        colour = "black",
        size = 2
      ) +
      scale_fill_manual(
        values = cols,
        na.value = "grey85",
        name = "Calcified"
      )
  } else {
    p <- p + geom_point(data = raw, aes(x = x, y = clasp))
  }

  p + theme_classic()
}
