#' Three-parameter logistic maternity curve
#'
#' Internal helper giving the expected proportion of females in maternal
#' condition as a function of length or age.
#' @param x Continuous predictor (length or age)
#' @param m50,m95 Values of \code{x} at which 50 and 95 percent of
#'   \code{pmax} are in maternal condition
#' @param pmax Upper asymptote: maximum proportion in maternal condition
#' @noRd
maternity_curve <- function(x, m50, m95, pmax) {
  pmax / (1 + exp(-log(19) * (x - m50) / (m95 - m50)))
}

#' Derive starting values for the maternity model
#'
#' The asymptote is taken from the proportion maternal among the largest
#' quarter of animals. Binned proportions, scaled by that asymptote, are then
#' interpolated to find where they cross 50 and 95 percent.
#' @param d Data frame with columns \code{x} and \code{matern}
#' @noRd
maternity_start <- function(d) {
  pmax0 <- mean(d$matern[d$x >= quantile(d$x, 0.75)])
  pmax0 <- min(max(pmax0, 0.05), 1)

  br <- seq(min(d$x), max(d$x), length.out = 21)
  bin <- cut(d$x, br, include.lowest = TRUE)
  mx <- tapply(d$x, bin, mean)
  my <- tapply(d$matern, bin, mean)
  ok <- !is.na(mx) & !is.na(my)
  mx <- mx[ok]
  my <- cummax(my[ok] / pmax0)

  m50_0 <- approx(my, mx, xout = 0.50, ties = "ordered", rule = 2)$y
  m95_0 <- approx(my, mx, xout = 0.95, ties = "ordered", rule = 2)$y
  if (!is.finite(m95_0) || m95_0 <= m50_0) {
    m95_0 <- m50_0 + 0.1 * diff(range(d$x))
  }

  list(m50 = m50_0, m95 = m95_0, pmax = pmax0)
}

#' Fit the maternity model with RTMB
#'
#' Builds the negative log-likelihood, optimises it under bounds, and returns
#' the optimiser result with the objective. Used for both the main fit and
#' each bootstrap resample.
#' @param d Data frame with columns \code{x} and \code{matern}
#' @param start Named list of starting values for m50, m95 and pmax
#' @param fixed Logical; hold \code{pmax} at its starting value
#' @noRd
maternity_fit <- function(d, start, fixed) {
  dat <- list(x = d$x, z = d$matern)

  nll <- function(p) {
    pr <- maternity_curve(dat$x, p$m50, p$m95, p$pmax)
    -sum(RTMB::dbinom(dat$z, 1, pr, log = TRUE))
  }

  par_map <- if (fixed) list(pmax = factor(NA)) else NULL
  obj <- RTMB::MakeADFun(nll, start[c("m50", "m95", "pmax")],
                         map = par_map, silent = TRUE)
  lower <- if (fixed) c(0, 0) else c(0, 0, 0)
  upper <- if (fixed) c(Inf, Inf) else c(Inf, Inf, 1)
  opt <- nlminb(obj$par, obj$fn, obj$gr, lower = lower, upper = upper)

  list(obj = obj, opt = opt)
}

#' Analyse length or age at maternity
#'
#' Fits the three-parameter logistic maternity function of Walker (2005) to
#' binary data on female maternal condition, as described in Harry et al.
#' (2024):
#'
#' \deqn{E[Y_i] = P_{Max}\left(1 + e^{-\ln(19)(x_i - x_{50})/(x_{95} - x_{50})}\right)^{-1}}
#'
#' where \eqn{Y_i} is a Bernoulli random variable indicating whether female
#' \eqn{i} is in maternal condition, \eqn{x_{50}} and \eqn{x_{95}} are the
#' lengths (or ages) at which 50 and 95 percent of the maximum proportion
#' \eqn{P_{Max}} are in maternal condition, and \eqn{P_{Max}} itself is the
#' proportion of females contributing to recruitment in a given year. The
#' model reduces to the familiar two-parameter maturity ogive when
#' \eqn{P_{Max} = 1}.
#'
#' Two methods from Harry et al. (2024) are available. With \code{pmax = NULL}
#' the asymptote is estimated from the data (\emph{3PLF-estimated}). Supplying
#' a value fixes it and estimates only \code{m50} and \code{m95}
#' (\emph{3PLF-fixed}), the approach of Walker (2005) where the asymptote is
#' chosen from knowledge of the ovarian and uterine cycles, e.g. 0.5 for a
#' biennial cycle or 1/3 for a triennial one. Fitting both and comparing
#' \code{AIC} provides a formal test of reproductive periodicity.
#'
#' The model is implemented in \code{RTMB} and estimated by maximum
#' likelihood. Confidence intervals on the parameters and on the fitted curve
#' are obtained by bootstrap resampling with \code{rsample}, refitting the
#' model to each resample; replicates that fail to converge or contain no
#' maternal females are dropped and the number reported.
#'
#' Harry et al. (2024) found that sample sizes of roughly 100–200 maternal
#' females were typically required to estimate \eqn{P_{Max}} accurately. With
#' fewer, fixing \code{pmax} from independent information is likely to be the
#' better choice.
#'
#' @param matern Binary maternal condition variable (0 = not maternal,
#'   1 = maternal), defined following Walker (2005) as whether a female would
#'   give birth or lay eggs in the current year.
#' @param x Continuous predictor variable (e.g. length, age)
#' @param data A data frame containing the above variables
#' @param pmax Upper asymptote. \code{NULL} (the default) estimates it from the
#'   data; a value in (0, 1] fixes it.
#' @param times Number of bootstrap replicates (default 1000)
#' @param start Optional named list of starting values for \code{m50},
#'   \code{m95} and \code{pmax}. Derived from the data if \code{NULL}.
#' @return A one row tibble of class \code{"maternity"} containing the list
#'   columns \code{data}, \code{coefs}, \code{preds}, \code{mods} and
#'   \code{boot_coefs}. \code{mods} holds the \code{RTMB} objective function,
#'   the \code{nlminb} result and the \code{sdreport}.
#' @references
#' Harry, A.V., Baremore, I.E. and Piercy, A.N. (2024) Quantifying maternal
#' reproductive output of chondrichthyan fishes. \emph{Canadian Journal of
#' Fisheries and Aquatic Sciences} \strong{81}(10), 1481–1494.
#' \doi{10.1139/cjfas-2024-0031}
#'
#' Walker, T.I. (2005) Reproduction in fisheries science. In: Hamlett, W.C.
#' (ed) \emph{Reproductive Biology and Phylogeny of Chondrichthyes}.
#' Science Publishers, Enfield, NH, pp. 81–127.
#' @examples
#' library(ggplot2)
#' data(sandbar)
#'
#' # Estimate the asymptote
#' mt <- maternity(maternity_stage, FL, data = sandbar, times = 200)
#' summary(mt)
#'
#' # Fix it at 0.5, as for a biennial cycle, and compare by AIC
#' mt_biennial <- maternity(maternity_stage, FL, data = sandbar,
#'                          pmax = 0.5, times = 200)
#' summary(mt_biennial)
#'
#' plot(mt) + xlab("Fork length (cm)") + ylab("Proportion in maternal condition")
#' @export
maternity <- function(matern, x, data, pmax = NULL, times = 1000, start = NULL) {
  # Bring in data
  new <- data |> transmute(x = {{ x }}, matern = {{ matern }})

  if (!all(new$matern %in% c(0L, 1L, NA))) {
    warning("'matern' contains values other than 0 and 1 — ensure it is a binary maternal condition indicator.")
  }

  new <- new[!is.na(new$x) & !is.na(new$matern), ]

  if (sum(new$matern) == 0) {
    stop("No females in maternal condition; cannot fit the model.")
  }
  if (nrow(new) < 5) {
    stop("Fewer than 5 usable observations; cannot fit the model.")
  }

  fixed <- !is.null(pmax)
  if (fixed && (!is.numeric(pmax) || pmax <= 0 || pmax > 1)) {
    stop("'pmax' must be NULL or a single value in (0, 1].")
  }

  # Starting values
  if (is.null(start)) start <- maternity_start(new)
  if (fixed) start$pmax <- pmax

  # Main fit
  fit <- try(maternity_fit(new, start, fixed), silent = TRUE)
  if (inherits(fit, "try-error")) {
    stop(
      "Model failed to fit. Try supplying starting values via 'start', ",
      "e.g. start = list(m50 = , m95 = , pmax = ).\n  ",
      attr(fit, "condition")$message
    )
  }
  obj <- fit$obj
  opt <- fit$opt
  if (opt$convergence != 0) {
    warning("Optimiser did not report convergence: ", opt$message)
  }
  sr <- RTMB::sdreport(obj)

  est <- as.list(opt$par)
  if (fixed) est$pmax <- pmax
  k <- base::length(opt$par)
  aic <- 2 * k + 2 * opt$objective

  # Bootstrap: refit from the main estimates, drop failures and resamples
  # containing no maternal females
  boot_splits <- rsample::bootstraps(new, times = times)
  boot_fits <- boot_splits$splits |>
    map(function(s) {
      d <- rsample::analysis(s)
      if (sum(d$matern) == 0) return(NULL)
      r <- try(maternity_fit(d, est, fixed), silent = TRUE)
      if (inherits(r, "try-error") || r$opt$convergence != 0) return(NULL)
      p <- as.list(r$opt$par)
      if (fixed) p$pmax <- pmax
      as.data.frame(p[c("m50", "m95", "pmax")])
    })
  ok <- !map_lgl(boot_fits, is.null)
  if (any(!ok)) {
    message(
      sum(!ok), " of ", times,
      " bootstrap replicates failed to converge or contained no maternal ",
      "females and were dropped."
    )
  }
  if (sum(ok) < 2) {
    stop("Fewer than 2 usable bootstrap replicates; increase 'times' or check the data.")
  }
  boot_coefs <- reduce(boot_fits[ok], rbind)

  # Prediction curve with bootstrap CI ribbon
  x_range <- seq(min(new$x), max(new$x), length.out = 200)
  boot_pred_mat <- boot_coefs |>
    nrow() |>
    seq_len() |>
    map(~ maternity_curve(
      x_range, boot_coefs$m50[.x], boot_coefs$m95[.x], boot_coefs$pmax[.x]
    )) |>
    reduce(cbind)

  pred <- data.frame(
    x      = x_range,
    matern = maternity_curve(x_range, est$m50, est$m95, est$pmax),
    lower  = apply(boot_pred_mat, 1, quantile, 0.025),
    upper  = apply(boot_pred_mat, 1, quantile, 0.975)
  )

  # Summary and coefficients
  ci <- function(p) signif(quantile(boot_coefs[[p]], c(0.025, 0.975)), 4)
  coefs <- data.frame(
    method      = if (fixed) "3PLF-fixed" else "3PLF-estimated",
    m50         = signif(est$m50, 4),
    m50_lower   = ci("m50")[1],
    m50_upper   = ci("m50")[2],
    m95         = signif(est$m95, 4),
    m95_lower   = ci("m95")[1],
    m95_upper   = ci("m95")[2],
    pmax        = signif(est$pmax, 4),
    pmax_lower  = if (fixed) NA_real_ else ci("pmax")[1],
    pmax_upper  = if (fixed) NA_real_ else ci("pmax")[2],
    n           = nrow(new),
    N           = sum(new$matern),
    nll         = signif(opt$objective, 4),
    AIC         = signif(aic, 4),
    convergence = opt$convergence == 0 && isTRUE(sr$pdHess)
  )
  rownames(coefs) <- NULL

  results <- tibble(
    data       = list(new),
    coefs      = list(coefs),
    preds      = list(pred),
    mods       = list(list(obj = obj, opt = opt, sdreport = sr)),
    boot_coefs = list(boot_coefs)
  )

  class(results) <- c("maternity", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.maternity <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.maternity <- function(x, raw_data = c("proportions", "point", "rug", "bootstrap", "none"),
                           binwidth = NULL, alpha = 1, n_boot = 100, ...) {
  raw_data <- match.arg(raw_data)
  raw  <- x$data[[1]]
  pred <- x$preds[[1]]

  if (raw_data == "bootstrap") {
    bc        <- x$boot_coefs[[1]]
    n_draw    <- min(n_boot, nrow(bc))
    bc_sample <- bc[sample(nrow(bc), n_draw), ]
    x_range   <- seq(min(raw$x), max(raw$x), length.out = 200)
    boot_curves <- do.call(rbind, lapply(seq_len(n_draw), function(i) {
      data.frame(
        x         = x_range,
        matern    = maternity_curve(x_range, bc_sample$m50[i], bc_sample$m95[i], bc_sample$pmax[i]),
        replicate = i
      )
    }))

    return(
      ggplot() +
        geom_line(data = boot_curves,
                  aes(x = x, y = matern, group = replicate),
                  colour = "grey70", linewidth = 0.3) +
        geom_line(data = pred, aes(x = x, y = matern)) +
        scale_y_continuous(limits = c(0, 1)) +
        theme_classic()
    )
  }

  p <- ggplot() +
    geom_ribbon(data = pred, aes(x = x, ymin = lower, ymax = upper),
                fill = "grey70") +
    geom_line(data = pred, aes(x = x, y = matern)) +
    scale_y_continuous(limits = c(0, 1)) +
    theme_classic()

  if (raw_data %in% c("proportions", "point")) {
    bw     <- if (is.null(binwidth)) diff(range(raw$x)) / 10 else binwidth
    breaks <- seq(min(raw$x), max(raw$x) + bw, by = bw)
    bin    <- cut(raw$x, breaks = breaks, include.lowest = TRUE)
    props  <- data.frame(
      x      = breaks[-base::length(breaks)] + bw / 2,
      matern = as.numeric(tapply(raw$matern, bin, mean)),
      n      = as.numeric(tapply(raw$matern, bin, base::length))
    )
    props <- props[!is.na(props$matern), ]
    if (raw_data == "proportions") {
      p <- p +
        geom_point(data = props, aes(x = x, y = matern, size = n), alpha = alpha) +
        scale_size_area(max_size = 6) +
        theme(legend.position = "none")
    } else {
      p <- p + geom_point(data = props, aes(x = x, y = matern), alpha = alpha)
    }
  } else if (raw_data == "rug") {
    p <- p +
      geom_rug(data = raw[raw$matern == 1, ], aes(x = x), sides = "t", alpha = 0.4) +
      geom_rug(data = raw[raw$matern == 0, ], aes(x = x), sides = "b", alpha = 0.4)
  }

  p
}
