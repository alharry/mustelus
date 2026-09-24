#' Von Bertalanffy growth curve parameterised by length at birth
#'
#' Internal helper. Uses \code{L0} in place of \code{t0}, so the curve passes
#' through length at birth at age zero.
#' @param age Age
#' @param Linf Asymptotic length
#' @param K Growth coefficient
#' @param L0 Length at birth
#' @noRd
growth_curve <- function(age, Linf, K, L0) {
  L0 + (Linf - L0) * (1 - exp(-K * age))
}

#' Coefficient of variation of ageing error
#'
#' Mean CV of replicate age readings across individuals, following Chang (1982)
#' as used by Cope and Punt (2007). Individuals whose readings average zero
#' contribute no information and are dropped.
#' @param m Matrix of replicate age readings, one row per individual
#' @noRd
ageing_cv <- function(m) {
  mu <- rowMeans(m)
  sdev <- apply(m, 1, stats::sd)
  cv <- sdev / mu
  cv <- cv[is.finite(cv)]
  if (base::length(cv) == 0) {
    stop("Could not compute an ageing CV from 'reads'; check the columns supplied.")
  }
  sqrt(sum(cv^2) / base::length(cv))
}

#' Analyse growth from length at age data
#'
#' Fits a von Bertalanffy growth model to length at age data, following
#' Harry et al. (2019), which builds on Cope and Punt (2007). The curve is
#' parameterised by length at birth rather than \eqn{t_0}:
#'
#' \deqn{L_{i,g}(a) = L_0 + (L_{\infty,g} - L_0)(1 - e^{-K_g a_{i,g}})}
#'
#' where \eqn{L_{\infty,g}} and \eqn{K_g} may differ between groups (typically
#' sexes) while \eqn{L_0} is shared. Observed length is normally distributed
#' about the curve with a standard deviation proportional to expected length,
#' \eqn{\sigma_{L} = CV_L L_{i,g}}, so variability in length at age grows with
#' size.
#'
#' Two optional extensions from the paper can each be switched on independently.
#'
#' \strong{Ageing error.} Supplying \code{reads}, two or more columns of
#' replicate age readings, treats true age as a random effect. Observed readings
#' are linked to true age by \eqn{A_{i,j} = a_i + \epsilon}, with
#' \eqn{\epsilon \sim N(0, (CV_a a_i)^2)}. The ageing CV is computed from the
#' replicate readings outside the likelihood and held fixed. Alternatively
#' \code{cv_age} supplies that CV directly, which is useful where only a
#' consensus age is available but the ageing CV is known from elsewhere. With
#' neither argument, age is treated as measured without error.
#'
#' \strong{Neonates.} Supplying \code{neonate}, an indicator for individuals of
#' known age zero such as those with an unhealed umbilical scar, adds their
#' lengths as direct information on \eqn{L_0} through
#' \eqn{L_{0,i} \sim N(L_0, (CV_L L_{0,i})^2)}. Flagged individuals are used only
#' for this term: any that also carry an age are removed from the length at age
#' data, since an age-zero observation and a length at birth observation carry
#' the same information and including both would count it twice.
#'
#' Estimation is by maximum likelihood using \code{RTMB}, with the random
#' effects integrated out by the Laplace approximation. Confidence intervals on
#' the fitted curve come from the delta method via \code{sdreport}; prediction
#' intervals add the individual variability \eqn{CV_L}.
#'
#' @param len Numeric vector of lengths
#' @param age Numeric vector of ages. Used directly when ageing error is off,
#'   and as the starting value for true age when it is on.
#' @param grouping_var Optional grouping variable (typically sex). Separate
#'   \code{Linf} and \code{K} are estimated per group; \code{L0} and \code{CV_L}
#'   are shared.
#' @param data A data frame containing the above variables
#' @param neonate Optional indicator for individuals of known age zero. Anything
#'   coercible to logical, e.g. \code{umb_scar \%in\% c("y", "p")}.
#' @param reads Optional replicate age reading columns, e.g.
#'   \code{c(reader1, reader2)}. Switches on ageing error.
#' @param cv_age Optional ageing CV supplied directly. An alternative to
#'   \code{reads} when only a consensus age is available.
#' @param start Optional named list of starting values for \code{Linf},
#'   \code{K}, \code{L0} and \code{CV_L}. Derived from the data if \code{NULL}.
#' @return A one row tibble of class \code{"growth"} containing the list columns
#'   \code{data}, \code{coefs}, \code{preds}, \code{mods} and \code{neonates}.
#'   \code{coefs} has one row per group, with \code{L0} and \code{CV_L} repeated
#'   since they are shared. \code{mods} holds the \code{RTMB} objective, the
#'   \code{nlminb} result and the \code{sdreport}.
#' @references
#' Cope, J.M. and Punt, A.E. (2007) Admitting ageing error when fitting growth
#' curves: an example using the von Bertalanffy growth function with random
#' effects. \emph{Canadian Journal of Fisheries and Aquatic Sciences}
#' \strong{64}(2), 205–218. \doi{10.1139/f06-179}
#'
#' Harry, A.V., Butcher, P.A., Macbeth, W.G., Morgan, J.A.T., Taylor, S.M. and
#' Geraghty, P.T. (2019) Life history of the common blacktip shark,
#' \emph{Carcharhinus limbatus}, from central eastern Australia and comparative
#' demography of a cryptic shark complex. \emph{Marine and Freshwater Research}
#' \strong{70}(6), 834–848. \doi{10.1071/MF18141}
#' @examples
#' library(ggplot2)
#' data(spottail)
#'
#' # Sex-specific growth, with neonates informing length at birth
#' g <- growth(length, age_agree, sex, data = spottail,
#'             neonate = umb_scar %in% c("y", "p"))
#'
#' summary(g)
#'
#' plot(g) + xlab("Age (years)") + ylab("Total length (mm)")
#' @export
growth <- function(len, age, grouping_var = NULL, data, neonate = NULL,
                   reads = NULL, cv_age = NULL, start = NULL) {
  new <- data |> transmute(len = {{ len }}, age = {{ age }})

  # Grouping variable
  grp_quo <- rlang::enquo(grouping_var)
  if (!rlang::quo_is_null(grp_quo)) {
    new$group <- as_factor(dplyr::pull(data, !!grp_quo))
    grp_missing <- is.na(new$group)
    message("The categorical variable ", rlang::as_label(grp_quo),
            " has ", nlevels(new$group), " levels.")
  } else {
    new$group <- factor("Unspecified")
  }

  # Known age-zero individuals
  neo_quo <- rlang::enquo(neonate)
  use_neo <- !rlang::quo_is_null(neo_quo)
  if (use_neo) {
    new$neonate <- as.logical(dplyr::pull(dplyr::mutate(data, .neo = !!neo_quo), ".neo"))
    new$neonate[is.na(new$neonate)] <- FALSE
  } else {
    new$neonate <- FALSE
  }

  # Replicate age readings
  read_quo <- rlang::enquo(reads)
  use_reads <- !rlang::quo_is_null(read_quo)
  if (use_reads) {
    rmat <- as.matrix(dplyr::select(data, !!read_quo))
    if (ncol(rmat) < 2) {
      stop("'reads' must select two or more columns of replicate age readings.")
    }
    new <- cbind(new, rmat)
    read_cols <- colnames(rmat)
  }

  # Neonate lengths, taken before the aged data are filtered
  len0 <- new$len[new$neonate & !is.na(new$len)]
  if (use_neo && base::length(len0) == 0) {
    warning("'neonate' flagged no usable individuals; length at birth will be estimated from the aged data alone.")
  }

  # Aged individuals. Neonates are excluded because an age-zero observation and
  # a length at birth observation carry the same information
  keep <- !is.na(new$len) & !is.na(new$age) & !is.na(new$group) & !new$neonate
  if (use_reads) keep <- keep & stats::complete.cases(new[, read_cols, drop = FALSE])
  if (!rlang::quo_is_null(grp_quo)) {
    n_na_grp <- sum(grp_missing & !new$neonate & !is.na(new$len) & !is.na(new$age))
    if (n_na_grp > 0) {
      message(n_na_grp, " row(s) with missing ", rlang::as_label(grp_quo),
              " were dropped.")
    }
  }
  n_dropped_neo <- sum(new$neonate & !is.na(new$len) & !is.na(new$age) & !is.na(new$group))
  if (n_dropped_neo > 0) {
    message(n_dropped_neo, " neonate(s) with an age were used only for length at birth, ",
            "not as length at age data.")
  }
  aged <- new[keep, ]
  aged$group <- droplevels(aged$group)

  if (nrow(aged) < 5) {
    stop("Fewer than 5 usable length at age observations; cannot fit the model.")
  }

  # Ageing error
  if (use_reads && !is.null(cv_age)) {
    stop("Supply either 'reads' or 'cv_age', not both.")
  }
  if (use_reads) {
    cv_age <- ageing_cv(as.matrix(aged[, read_cols, drop = FALSE]))
    message("Ageing CV computed from ", base::length(read_cols),
            " readings: ", signif(cv_age, 3), ".")
  }
  use_err <- !is.null(cv_age)
  if (use_err && (!is.numeric(cv_age) || cv_age <= 0)) {
    stop("'cv_age' must be a single positive value.")
  }

  g_idx <- as.integer(aged$group)
  n_grp <- nlevels(aged$group)
  eps <- 1e-8

  # Prediction grid, one sequence per group over its observed age range
  pred_grid <- do.call(rbind, lapply(seq_len(n_grp), function(k) {
    a <- aged$age[g_idx == k]
    data.frame(group = levels(aged$group)[k],
               age = seq(0, max(a), length.out = 100),
               gi = k)
  }))

  dat <- list(
    len = aged$len, age = aged$age, sex = g_idx,
    len0 = len0, n0 = base::length(len0),
    pred_age = pred_grid$age, pred_gi = pred_grid$gi,
    cv_age = if (use_err) cv_age else 0
  )
  # With 'reads' every reading is an observation of true age; with 'cv_age'
  # the single supplied age is the one observation
  if (use_err) {
    dat$reads <- if (use_reads) {
      as.matrix(aged[, read_cols, drop = FALSE])
    } else {
      matrix(aged$age, ncol = 1)
    }
  }

  # Starting values
  if (is.null(start)) {
    start <- list(
      Linf = rep(max(aged$len) * 1.05, n_grp),
      K = rep(0.2, n_grp),
      L0 = if (base::length(len0) > 0) mean(len0) else min(aged$len),
      CV_L = 0.1
    )
  }
  pars <- start[c("Linf", "K", "L0", "CV_L")]
  if (use_err) pars$age_re <- pmax(aged$age, eps)

  nll <- function(p) {
    Linf <- p$Linf; K <- p$K; L0 <- p$L0; CV_L <- p$CV_L
    a <- if (use_err) p$age_re else dat$age

    Lt <- growth_curve(a, Linf[dat$sex], K[dat$sex], L0)
    j <- -sum(RTMB::dnorm(dat$len, Lt, CV_L * Lt + eps, log = TRUE))

    # Neonates inform length at birth directly. The standard deviation is
    # taken on the observed length, as in Harry et al. (2019); this
    # reproduces the published estimates exactly
    if (dat$n0 > 0) {
      j <- j - sum(RTMB::dnorm(dat$len0, L0, CV_L * dat$len0 + eps, log = TRUE))
    }

    # Ageing error: every reading is an observation of true age. The original
    # C++ looped from the second column, so the first reader was never used
    if (use_err) {
      sd_a <- dat$cv_age * a + eps
      for (k in seq_len(ncol(dat$reads))) {
        j <- j - sum(RTMB::dnorm(dat$reads[, k], a, sd_a, log = TRUE))
      }
    }

    pred_len <- growth_curve(dat$pred_age, Linf[dat$pred_gi], K[dat$pred_gi], L0)
    RTMB::ADREPORT(pred_len)
    j
  }

  obj <- RTMB::MakeADFun(nll, pars,
                         random = if (use_err) "age_re" else NULL,
                         silent = TRUE)
  n_fixed <- base::length(obj$par)
  opt <- try(nlminb(obj$par, obj$fn, obj$gr,
                    lower = rep(eps, n_fixed),
                    upper = c(rep(Inf, 2 * n_grp + 1), 1)),
             silent = TRUE)
  if (inherits(opt, "try-error")) {
    stop("Model failed to fit. Try supplying starting values via 'start'.\n  ",
         attr(opt, "condition")$message)
  }
  if (opt$convergence != 0) {
    warning("Optimiser did not report convergence: ", opt$message)
  }
  sr <- RTMB::sdreport(obj)

  fx <- summary(sr, "fixed")
  est <- fx[, "Estimate"]
  se <- fx[, "Std. Error"]
  nm <- rownames(fx)

  # A standard error wider than the data indicates a flat likelihood
  poorly_identified <- nm[!is.finite(se) | se > diff(range(aged$len))]
  if (base::length(poorly_identified) > 0) {
    warning("Parameter(s) ", paste(unique(poorly_identified), collapse = ", "),
            " are poorly identified: the standard error exceeds the range of ",
            "the data. Check that the age range covers the growth trajectory.")
  }

  # Fitted curve with confidence and prediction intervals
  rep_tab <- summary(sr, "report")
  pred_len <- rep_tab[, "Estimate"]
  pred_sd <- rep_tab[, "Std. Error"]
  cv_l_hat <- est[nm == "CV_L"]
  pred <- data.frame(
    group = pred_grid$group,
    age = pred_grid$age,
    len = pred_len,
    lower = pred_len - 1.96 * pred_sd,
    upper = pred_len + 1.96 * pred_sd,
    plower = pred_len - 1.96 * sqrt(pred_sd^2 + (pred_len * cv_l_hat)^2),
    pupper = pred_len + 1.96 * sqrt(pred_sd^2 + (pred_len * cv_l_hat)^2)
  )

  # Coefficients, one row per group with the shared parameters repeated
  pick <- function(p, k = NULL) {
    i <- which(nm == p)
    if (!is.null(k)) i <- i[k]
    c(est = unname(est[i]), se = unname(se[i]))
  }
  coefs <- do.call(rbind, lapply(seq_len(n_grp), function(k) {
    Li <- pick("Linf", k); Ki <- pick("K", k)
    L0i <- pick("L0"); CVi <- pick("CV_L")
    data.frame(
      group      = levels(aged$group)[k],
      Linf       = signif(Li[["est"]], 4),
      Linf_lower = signif(Li[["est"]] - 1.96 * Li[["se"]], 4),
      Linf_upper = signif(Li[["est"]] + 1.96 * Li[["se"]], 4),
      K          = signif(Ki[["est"]], 4),
      K_lower    = signif(Ki[["est"]] - 1.96 * Ki[["se"]], 4),
      K_upper    = signif(Ki[["est"]] + 1.96 * Ki[["se"]], 4),
      L0         = signif(L0i[["est"]], 4),
      L0_lower   = signif(L0i[["est"]] - 1.96 * L0i[["se"]], 4),
      L0_upper   = signif(L0i[["est"]] + 1.96 * L0i[["se"]], 4),
      CV_L       = signif(CVi[["est"]], 4),
      n          = sum(g_idx == k)
    )
  }))
  coefs$n0 <- base::length(len0)
  coefs$cv_age <- if (use_err) signif(cv_age, 4) else NA_real_
  coefs$nll <- signif(opt$objective, 5)
  coefs$AIC <- signif(2 * n_fixed + 2 * opt$objective, 5)
  coefs$convergence <- opt$convergence == 0 && isTRUE(sr$pdHess) &&
    base::length(poorly_identified) == 0
  rownames(coefs) <- NULL

  results <- tibble(
    data      = list(aged),
    coefs     = list(coefs),
    preds     = list(pred),
    mods      = list(list(obj = obj, opt = opt, sdreport = sr)),
    neonates  = list(len0)
  )

  class(results) <- c("growth", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.growth <- function(x, ...) {
  return(x$coefs |> tibble() |> unnest(cols = everything()))
}

#' @export
plot.growth <- function(x, ...) {
  raw <- x$data[[1]]
  pred <- x$preds[[1]]
  multi <- nlevels(raw$group) > 1

  p <- ggplot() +
    geom_ribbon(data = pred, aes(x = age, ymin = plower, ymax = pupper),
                col = "black", fill = "transparent", linetype = "dotted") +
    geom_ribbon(data = pred, aes(x = age, ymin = lower, ymax = upper),
                col = "black", fill = "transparent", linetype = "dashed") +
    geom_line(data = pred, aes(x = age, y = len)) +
    geom_point(data = raw, aes(x = age, y = len), alpha = 0.6) +
    theme_classic()

  if (multi) p <- p + facet_wrap(~group)
  p
}
