#' Likelihood confidence regions for growth parameters
#'
#' Constructs approximate joint confidence regions for \eqn{L_\infty} and
#' \eqn{K} from a \code{\link{growth}} fit, following Kimura (1980). Unlike an
#' ellipse drawn from the covariance matrix of the estimates, the region
#' follows a contour of equal likelihood and need not be symmetrical about the
#' estimates.
#'
#' Kimura (1980) defined the region by the residual sum of squares,
#' \deqn{S(L_\infty, K, t_0) \le \hat{S}\left(1 + \frac{p}{N - p} F_{p, N-p}(1 - \alpha)\right)}
#' with \eqn{p = 3} parameters and \eqn{N} observations, and displayed it as
#' the two-dimensional cross-section for \eqn{L_\infty} and \eqn{K} with
#' \eqn{t_0} held at its estimate. \code{growth()} maximises a likelihood with
#' a standard deviation that changes with length, so the same criterion is
#' applied to the log-likelihood \eqn{\ell}:
#' \deqn{2\left[\hat{\ell} - \ell(L_\infty, K)\right] \le N \log\left(1 + \frac{p}{N - p} F_{p, N-p}(1 - \alpha)\right)}
#' For a single group with constant variance this is identical to Kimura's
#' criterion. \eqn{N} is the number of aged individuals in the group.
#'
#' \eqn{L_0} takes the place of \eqn{t_0} and is held at its estimate, as are
#' the parameters of the other groups. \eqn{CV_L} is re-estimated at each
#' point, as \eqn{\sigma} effectively is in the ratio of sums of squares. As
#' Kimura noted, holding the third parameter fixed gives a cross-section of
#' the region rather than a true confidence region, since more extreme values
#' of \eqn{L_\infty} and \eqn{K} may occur at a different value of it. Setting
#' \code{profile_L0 = TRUE} re-estimates \eqn{L_0} at each point as well,
#' giving the projection of the full three-parameter region onto
#' \eqn{L_\infty} and \eqn{K}. The two are close when \eqn{L_0} is well
#' determined, for example by neonates. When it is not, the projection can
#' be noticeably wider, mainly in \eqn{K}.
#'
#' As in Kimura (1980), the boundary is found by stepping through values of
#' \eqn{K} and solving for the two values of \eqn{L_\infty} at which the
#' likelihood reaches the critical value. This follows regions that are
#' strongly curved, as they often are when few old animals have been aged.
#' For models with ageing error each evaluation of the likelihood includes
#' the Laplace approximation, and the calculation takes longer.
#'
#' @param x An object returned by \code{\link{growth}}
#' @param level Confidence level
#' @param profile_L0 Re-estimate \eqn{L_0} at each point rather than holding
#'   it at its estimate
#' @param n_steps Number of values of \eqn{K} at which the boundary is found
#' @return A tibble of class \code{"growth_region"} with one row per group,
#'   holding the estimates, the number of aged individuals \code{n}, the
#'   critical value \code{crit}, and the boundary of the region in the list
#'   column \code{region}. \code{summary()} gives the range of \eqn{L_\infty}
#'   and \eqn{K} within each region.
#' @references
#' Kimura, D.K. (1980) Likelihood methods for the von Bertalanffy growth
#' curve. \emph{Fishery Bulletin} \strong{77}(4), 765-776.
#' @examples
#' library(ggplot2)
#' data(blacktip)
#'
#' g <- growth(STL, age_agree, sex, data = blacktip, neonate = neonate)
#' r <- growth_region(g)
#'
#' summary(r)
#'
#' plot(r) + labs(x = "Linf (cm)", y = "K (per year)", linetype = "Sex")
#' @export
growth_region <- function(x, level = 0.95, profile_L0 = FALSE, n_steps = 50) {
  if (!inherits(x, "growth")) {
    stop("'x' must be an object returned by growth().")
  }
  mod <- x$mods[[1]]
  obj <- mod$obj
  est <- mod$opt$par
  nll_hat <- mod$opt$objective
  V <- mod$sdreport$cov.fixed
  aged <- x$data[[1]]
  groups <- levels(aged$group)
  n_aged <- as.vector(table(aged$group))
  p <- 3

  if (any(n_aged <= p)) {
    stop("Each group needs more than ", p, " aged individuals.")
  }

  i_linf <- which(names(est) == "Linf")
  i_k <- which(names(est) == "K")
  i_nuis <- which(names(est) %in% if (profile_L0) c("L0", "CV_L") else "CV_L")

  # The search for the boundary is scaled by the standard errors, so it needs
  # a fit at a proper optimum
  v <- diag(V)[c(i_linf, i_k)]
  if (mod$opt$convergence != 0 || any(!is.finite(v) | v <= 0)) {
    stop("growth_region() needs a fit that converged with finite standard ",
         "errors for Linf and K. Check the warnings from growth().")
  }

  # Negative log-likelihood with Linf and K of group k set to new values and
  # the nuisance parameters re-estimated. Failed evaluations count as outside
  nll_at <- function(k, Linf, K) {
    par <- est
    par[c(i_linf[k], i_k[k])] <- c(Linf, K)
    f <- function(z) {
      par[i_nuis] <- z
      v <- tryCatch(obj$fn(par), error = function(e) NA)
      if (is.finite(v)) v else 1e10
    }
    if (base::length(i_nuis) == 1) {
      stats::optimize(f, est[i_nuis] * c(0.5, 2))$objective
    } else {
      nlminb(est[i_nuis], f, lower = 1e-8)$objective
    }
  }

  se_all <- sqrt(diag(V))
  open <- character(0)

  regions <- lapply(seq_along(groups), function(k) {
    crit <- n_aged[k] * log(1 + p / (n_aged[k] - p) *
                              stats::qf(level, p, n_aged[k] - p))
    linf_hat <- est[i_linf[k]]
    k_hat <- est[i_k[k]]
    se_linf <- se_all[i_linf[k]]
    se_k <- se_all[i_k[k]]
    linf_lo <- max(1e-8, linf_hat - 20 * se_linf)
    linf_hi <- linf_hat + 20 * se_linf

    # Distance of the likelihood ratio statistic from the critical value;
    # negative inside the region
    dev <- function(Linf, K) {
      if (Linf <= 0 || K <= 0) return(1e10)
      2 * (nll_at(k, Linf, K) - nll_hat) - crit
    }

    # Lowest point of the likelihood surface over Linf at a given K. A lowest
    # point at the edge of the search means the region extends beyond it
    ridge <- function(K) {
      o <- stats::optimize(function(L) dev(L, K), c(linf_lo, linf_hi),
                           tol = se_linf / 100)
      if (o$objective < 0 && o$minimum > linf_hi - se_linf) {
        open <<- c(open, groups[k])
      }
      c(Linf = o$minimum, dev = o$objective)
    }

    # Smallest and largest K in the region, where the ridge reaches the
    # critical value. Steps toward zero are limited so that K stays positive
    k_edge <- function(direction) {
      step <- se_k
      k_in <- k_hat
      repeat {
        k_out <- if (direction > 0) k_in + step else max(k_in - step, k_in / 2)
        if (ridge(k_out)[["dev"]] > 0) break
        k_in <- k_out
        step <- step * 1.5
        if (k_in < k_hat / 1000 || k_in > k_hat * 1000) {
          open <<- c(open, groups[k])
          return(k_in)
        }
      }
      stats::uniroot(function(K) ridge(K)[["dev"]], sort(c(k_in, k_out)),
                     tol = se_k / 1000)$root
    }

    # Following Kimura, step through K and solve for the two values of Linf on
    # the boundary. Steps are closer together near the ends of the region
    k_min <- k_edge(-1)
    k_max <- k_edge(1)
    ks <- (k_min + k_max) / 2 -
      (k_max - k_min) / 2 * cos(pi * seq(0, 1, length.out = n_steps))

    bounds <- t(vapply(ks, function(K) {
      r <- ridge(K)
      if (r[["dev"]] >= 0) return(rep(r[["Linf"]], 2))
      side <- function(edge) {
        if (dev(edge, K) < 0) {
          open <<- c(open, groups[k])
          return(edge)
        }
        stats::uniroot(function(L) dev(L, K), sort(c(edge, r[["Linf"]])),
                       tol = se_linf / 1000)$root
      }
      c(side(linf_lo), side(linf_hi))
    }, numeric(2)))

    list(crit = crit,
         region = data.frame(
           Linf = c(bounds[, 1], rev(bounds[, 2]), bounds[1, 1]),
           K = c(ks, rev(ks), ks[1])
         ))
  })

  # Leave the model object as it was found
  obj$fn(est)

  if (base::length(open) > 0) {
    warning("The region for group(s) ", paste(unique(open), collapse = ", "),
            " is not closed, and is shown only as far as Linf = estimate + ",
            "20 standard errors: Linf and K are poorly identified.")
  }

  results <- tibble(
    group  = groups,
    Linf   = unname(est[i_linf]),
    K      = unname(est[i_k]),
    n      = n_aged,
    crit   = vapply(regions, function(r) r$crit, numeric(1)),
    region = lapply(regions, function(r) r$region)
  )
  attr(results, "level") <- level
  attr(results, "profile_L0") <- profile_L0
  class(results) <- c("growth_region", "tbl_df", "tbl", "data.frame")
  results
}

#' @export
summary.growth_region <- function(object, ...) {
  tibble(
    group    = object$group,
    Linf     = signif(object$Linf, 4),
    Linf_min = signif(vapply(object$region, function(r) min(r$Linf), numeric(1)), 4),
    Linf_max = signif(vapply(object$region, function(r) max(r$Linf), numeric(1)), 4),
    K        = signif(object$K, 4),
    K_min    = signif(vapply(object$region, function(r) min(r$K), numeric(1)), 4),
    K_max    = signif(vapply(object$region, function(r) max(r$K), numeric(1)), 4),
    n        = object$n,
    level    = attr(object, "level")
  )
}

#' @export
plot.growth_region <- function(x, ...) {
  reg <- do.call(rbind, lapply(seq_len(nrow(x)), function(k) {
    data.frame(group = x$group[k], x$region[[k]])
  }))
  est <- data.frame(group = x$group, Linf = x$Linf, K = x$K)

  p <- ggplot(reg, aes(x = Linf, y = K))
  p <- if (nrow(x) > 1) {
    p + geom_path(aes(linetype = group))
  } else {
    p + geom_path()
  }
  p + geom_point(data = est) + theme_classic()
}
