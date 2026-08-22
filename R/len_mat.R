#' Analyse length or age at maturity
#'
#' Fits a logistic regression model (binomial GLM) of maturity stage as a
#' function of length, age, or another continuous predictor. Bootstrap
#' confidence intervals are computed via \code{rsample}.
#' @param mat Binary maturity variable (0 = immature, 1 = mature)
#' @param len Continuous predictor variable (e.g. length, age)
#' @param grouping_var Optional categorical grouping variable (e.g. sex). Will be converted to a factor.
#' @param data A data frame containing the above variables
#' @param times Number of bootstrap replicates (default 1000)
#' @return A nested tibble of class \code{"len_mat"} with one row per group,
#'   containing list columns \code{data}, \code{coefs}, \code{preds}, and \code{mods},
#'   each named by the grouping variable level.
#' @examples
#' data(spottail)
#'
#' lm50 <- len_mat(maturity_stage, length, sex, data = spottail, times = 100)
#'
#' summary(lm50)
#'
#' plot(lm50)
#' @export
len_mat <- function(mat, len, grouping_var = NULL, data, times = 1000) {
  # Bring in data
  new <- data |> transmute(len = {{ len }}, mat = {{ mat }})

  # Validate maturity variable
  if (!all(new$mat %in% c(0L, 1L, NA))) {
    warning("'mat' contains values other than 0 and 1 — ensure it is a binary maturity indicator.")
  }

  # If grouping_var is provided, add it to data
  grp_quo <- rlang::enquo(grouping_var)
  if (!rlang::quo_is_null(grp_quo)) {
    new$grouping_var <- as_factor(dplyr::pull(data, !!grp_quo))
    message(
      "The categorical variable ", rlang::as_label(grp_quo),
      " has ", nlevels(new$grouping_var), " levels."
    )
  } else {
    new$grouping_var <- factor("Unspecified")
  }

  new <- new[!is.na(new$len) & !is.na(new$mat), ]

  # Append pooled group if more than one level
  if (base::length(levels(droplevels(new$grouping_var))) > 1) {
    new <- rbind(mutate(new, grouping_var = "all"), new)
  }

  # Per-group modelling function
  len_mat_mod <- function(data) {
    m <- glm(mat ~ len, family = binomial, data = data)
    a <- coef(m)[[1]]
    b <- coef(m)[[2]]
    L50 <- -a / b
    L95 <- (log(0.95 / 0.05) - a) / b

    # Bootstrap resamples
    boot_splits <- rsample::bootstraps(data, times = times)
    boot_stats <- boot_splits |>
      mutate(
        mod_b = map(splits, ~ glm(mat ~ len, family = binomial, data = rsample::analysis(.x))),
        L50_b = map_dbl(mod_b, ~ -coef(.x)[[1]] / coef(.x)[[2]]),
        L95_b = map_dbl(mod_b, ~ (log(0.95 / 0.05) - coef(.x)[[1]]) / coef(.x)[[2]])
      )

    coefs <- data.frame(
      a         = signif(a, 4),
      b         = signif(b, 4),
      L50       = signif(L50, 4),
      L50_lower = signif(quantile(boot_stats$L50_b, 0.025), 4),
      L50_upper = signif(quantile(boot_stats$L50_b, 0.975), 4),
      L95       = signif(L95, 4),
      L95_lower = signif(quantile(boot_stats$L95_b, 0.025), 4),
      L95_upper = signif(quantile(boot_stats$L95_b, 0.975), 4),
      n         = base::length(m$residuals),
      N         = sum(data$mat, na.rm = TRUE)
    )

    # Prediction curve with bootstrap CI ribbon
    len_range <- seq(min(data$len, na.rm = TRUE), max(data$len, na.rm = TRUE), length.out = 200)
    boot_pred_mat <- boot_stats$mod_b |>
      map(~ predict(.x, newdata = data.frame(len = len_range), type = "response")) |>
      reduce(cbind)

    pred <- data.frame(
      len   = len_range,
      mat   = predict(m, newdata = data.frame(len = len_range), type = "response"),
      lower = apply(boot_pred_mat, 1, quantile, 0.025),
      upper = apply(boot_pred_mat, 1, quantile, 0.975)
    )

    # Store bootstrap coefficients for optional curve visualisation
    boot_coefs <- data.frame(
      a = map_dbl(boot_stats$mod_b, ~ coef(.x)[[1]]),
      b = map_dbl(boot_stats$mod_b, ~ coef(.x)[[2]])
    )

    list(coefs = coefs, pred = pred, mod = m, boot_coefs = boot_coefs)
  }

  results <- new |>
    group_by(grouping_var) |>
    nest() |>
    mutate(
      .fit       = map(data, ~ len_mat_mod(.x)),
      coefs      = map(.fit, "coefs"),
      preds      = map(.fit, "pred"),
      mods       = map(.fit, "mod"),
      boot_coefs = map(.fit, "boot_coefs")
    ) |>
    select(-.fit) |>
    mutate(across(c(data, coefs, preds, mods, boot_coefs), ~ set_names(., grouping_var)))

  class(results) <- c("len_mat", "tbl_df", "tbl", "data.frame")
  return(invisible(results))
}

#' @export
summary.len_mat <- function(x, ...) {
  x$coefs |> tibble() |> unnest(cols = everything())
}

#' @export
plot.len_mat <- function(x, raw_data = c("proportions", "point", "rug", "bootstrap", "none"),
                         binwidth = NULL, alpha = 1, n_boot = 100, ...) {
  raw_data  <- match.arg(raw_data)
  plot_lims <- x[which(x$grouping_var %in% c("all", "Unspecified")), ]

  len_mat_plots <- x |>
    group_split(grouping_var) |>
    map(function(grp) {
      raw  <- grp$data[[1]]
      pred <- grp$preds[[1]]

      if (raw_data == "bootstrap") {
        bc        <- grp$boot_coefs[[1]]
        n_draw    <- min(n_boot, nrow(bc))
        bc_sample <- bc[sample(nrow(bc), n_draw), ]
        len_range <- seq(min(raw$len, na.rm = TRUE), max(raw$len, na.rm = TRUE), length.out = 200)
        boot_curves <- do.call(rbind, lapply(seq_len(n_draw), function(i) {
          data.frame(
            len       = len_range,
            mat       = 1 / (1 + exp(-(bc_sample$a[i] + bc_sample$b[i] * len_range))),
            replicate = i
          )
        }))

        p <- ggplot() +
          geom_line(data = boot_curves,
                    aes(x = len, y = mat, group = replicate),
                    colour = "grey70", linewidth = 0.3) +
          geom_line(data = pred, aes(x = len, y = mat)) +
          geom_point(data = plot_lims$data[[1]], aes(x = len, y = 0),
                     col = "transparent") +
          scale_y_continuous(limits = c(0, 1)) +
          theme_classic()
        return(p)
      }

      p <- ggplot() +
        geom_ribbon(data = pred, aes(x = len, ymin = lower, ymax = upper),
                    fill = "grey70") +
        geom_line(data = pred, aes(x = len, y = mat)) +
        geom_point(data = plot_lims$data[[1]], aes(x = len, y = 0),
                   col = "transparent") +
        scale_y_continuous(limits = c(0, 1)) +
        theme_classic()

      if (raw_data %in% c("proportions", "point")) {
        bw     <- if (is.null(binwidth)) diff(range(raw$len, na.rm = TRUE)) / 10 else binwidth
        breaks <- seq(min(raw$len, na.rm = TRUE), max(raw$len, na.rm = TRUE) + bw, by = bw)
        bin    <- cut(raw$len, breaks = breaks, include.lowest = TRUE)
        props  <- data.frame(
          len = breaks[-base::length(breaks)] + bw / 2,
          mat = as.numeric(tapply(raw$mat, bin, mean, na.rm = TRUE)),
          n   = as.numeric(tapply(raw$mat, bin, base::length))
        )
        props <- props[!is.na(props$mat), ]
        if (raw_data == "proportions") {
          p <- p +
            geom_point(data = props, aes(x = len, y = mat, size = n), alpha = alpha) +
            scale_size_area(max_size = 6) +
            theme(legend.position = "none")
        } else {
          p <- p +
            geom_point(data = props, aes(x = len, y = mat), alpha = alpha)
        }
      } else if (raw_data == "rug") {
        p <- p +
          geom_rug(data = raw[raw$mat == 1, ], aes(x = len), sides = "t", alpha = 0.4) +
          geom_rug(data = raw[raw$mat == 0, ], aes(x = len), sides = "b", alpha = 0.4)
      }

      p
    })

  names(len_mat_plots) <- x$grouping_var
  return(len_mat_plots)
}
