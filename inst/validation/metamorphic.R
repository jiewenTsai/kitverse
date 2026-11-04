# Metamorphic relations for the KIT R packages (kits, kitsUI, kitJoin)
#
# Rule: for each in-scope function, exactly THREE metamorphic relations: a transformation of the
# input with a known effect on the output (no external oracle). Each relation is checked once on
# fixed data: simulated data (kits::kits_sim with fixed seeds), the demo data kits::kitm03 /
# kits::kitm36 (through kitsUI's kitsui_demo()), or small hand-made data frames.
# No real study data are read.
#
# Run: source(system.file("validation", "metamorphic.R", package = "kitverse"))
#      (writes metamorphic_results.csv to KIT_VALIDATION_OUT)
# The packages are used as installed; internal functions are taken from their namespaces.

suppressPackageStartupMessages({
  library(kits)
  library(dplyr)
})
set.seed(20261104)
t_start <- Sys.time()

# Results go to KIT_VALIDATION_OUT (default: a folder in tempdir()); the installed package is not written to
out_dir <- Sys.getenv("KIT_VALIDATION_OUT", file.path(tempdir(), "kit_validation"))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Internal functions of kitsUI and kitJoin
grab <- function(pkg, names) {
  ns <- asNamespace(pkg)
  for (f in names) assign(f, get(f, envir = ns), envir = globalenv())
}
grab("kitsUI", c("kitsui_demo", "kitsui_fixed_empty", "kitsui_round", "kitsui_cap",
                 "kitsui_category_problems", "kitsui_score", "kitsui_link_internal",
                 "kitsui_persons"))
grab("kitJoin", c("replace_na_codes", "join_waves", "build_attrition", "reshape_wider",
                  "reshape_longer", "wider_args", "longer_args", "stack_waves", "kits_build",
                  "kits_guess_map", "kits_candidate_cols", "kits_mapped_cols",
                  "kits_settings_apply", "kits_item_settings", "kits_spec",
                  "kits_settings_items", "kits_settings_undecided", "kits_bulk_shift",
                  "write_kits_long_gz"))

# ---- recorder ---------------------------------------------------------------------------------
results <- list()
check <- function(package, fun, relation_id, relation, error_type, tolerance, expr) {
  t0 <- Sys.time()
  res <- tryCatch(
    suppressWarnings(suppressMessages(force(expr))),
    error = function(e) list(diff = NA_real_, note = paste("ERROR:", conditionMessage(e)))
  )
  if (!is.list(res)) res <- list(diff = res, note = "")
  d <- as.numeric(res$diff)
  pass <- !is.na(d) && is.finite(d) && d <= tolerance
  secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2)
  note <- paste0(if (!is.null(res$note) && nzchar(res$note)) paste0(res$note, "; ") else "",
                 "runtime ", secs, " s")
  results[[length(results) + 1]] <<- data.frame(
    package = package, `function` = fun, relation_id = relation_id, relation = relation,
    error_type = error_type, max_abs_diff = signif(d, 4), tolerance = tolerance, pass = pass,
    note = note, check.names = FALSE, stringsAsFactors = FALSE
  )
  cat(sprintf("[%s] %-9s %-26s %s  diff=%s\n", if (pass) "PASS" else "FAIL", package, fun,
              relation_id, format(signif(d, 3))))
}
# max absolute difference of numeric vectors; length or NA-pattern mismatch -> Inf
mad_ <- function(a, b) {
  a <- as.numeric(a); b <- as.numeric(b)
  if (length(a) != length(b) || !identical(is.na(a), is.na(b))) return(Inf)
  if (length(a) == 0 || all(is.na(a))) return(0)
  max(abs(a - b), na.rm = TRUE)
}
# number of mismatching elements of two vectors (any type); length mismatch -> Inf
mis_ <- function(a, b) {
  if (length(a) != length(b)) return(Inf)
  sum(!(is.na(a) & is.na(b)) & (is.na(a) != is.na(b) | a != b), na.rm = TRUE) +
    sum(xor(is.na(a), is.na(b)))
}
coef_key <- function(it) {
  cf <- as.data.frame(coef(it))
  cf[order(cf$item_id, cf$item_score), ]
}

# ---- fixed simulated data (kits) --------------------------------------------------------------
betas <- list(a1 = c(-1, 0), a2 = c(0, 1), a3 = 0.5, a4 = -0.5, a5 = c(-0.5, 0.5), a6 = 1.5)
set.seed(1)
X <- kits_sim(rnorm(500), betas, seed = 1)
item <- kits_item(X, scale = "A")
parms <- as.data.frame(coef(item))[c("item_id", "item_score", "beta")]

# two cohorts with common items a3, a4, a5 (linking, convert)
b2 <- list(a1 = -2, a2 = -1, a3 = c(-0.5, 0.5), a4 = 0, a5 = c(0.5, 1.5), a6 = 2, a7 = 3)
set.seed(2)
young <- kits_sim(rnorm(500, 0), b2[1:5], seed = 1)
old <- kits_sim(rnorm(500, 2), b2[3:7], prefix = "q", seed = 2)
item_old <- kits_item(old, scale = "old")
item_young <- kits_item(young, scale = "young")

# =============================================================================================
# kits
# =============================================================================================

# ---- kits_item ----
check("kits", "kits_item", "R1",
      "Permuting the persons (rows) and the items (columns) leaves every beta, beta_se and thr unchanged.",
      "data_management", 1e-6, {
        Xp <- X[sample(nrow(X)), rev(colnames(X))]
        a <- coef_key(item); b <- coef_key(kits_item(Xp, scale = "A"))
        list(diff = max(mad_(a$beta, b$beta), mad_(a$beta_se, b$beta_se), mad_(a$thr, b$thr)),
             note = "max over beta, beta_se, thr")
      })
check("kits", "kits_item", "R2",
      "Duplicating every person leaves beta unchanged and divides beta_se by sqrt(2).",
      "interval", 1e-6, {
        X2 <- rbind(X, X)
        rownames(X2) <- c(rownames(X), paste0(rownames(X), "_dup"))
        a <- coef_key(item); b <- coef_key(kits_item(X2, scale = "A"))
        list(diff = max(mad_(a$beta, b$beta), mad_(a$beta_se / sqrt(2), b$beta_se)),
             note = "max over beta and beta_se/sqrt(2)")
      })
check("kits", "kits_item", "R3",
      "Adding an item column that is all NA and a person row that is all NA leaves the calibration unchanged.",
      "boundary", 1e-8, {
        X3 <- cbind(X, a_empty = NA_integer_)
        X3 <- rbind(X3, empty_person = NA_integer_)
        a <- coef_key(item); b <- coef_key(kits_item(X3, scale = "A"))
        list(diff = max(mad_(a$beta, b$beta), mad_(a$beta_se, b$beta_se), mis_(a$item_id, b$item_id)),
             note = sprintf("n_persons %d vs %d", item$n_persons, kits_item(X3, scale = "A")$n_persons))
      })

# ---- kits_subj ----
s0 <- kits_subj(X, parms)
check("kits", "kits_subj", "R1",
      "Adding a constant c = 1.5 to every beta adds c to every theta and leaves every SE unchanged.",
      "formula", 1e-5, {
        p2 <- parms; p2$beta <- p2$beta + 1.5
        s2 <- kits_subj(X, p2)
        list(diff = max(mad_(s2$theta - 1.5, s0$theta), mad_(s2$se, s0$se)))
      })
check("kits", "kits_subj", "R2",
      "Permuting the persons leaves each person's theta, se and raw unchanged (matched by visit_id).",
      "data_management", 1e-8, {
        Xp <- X[sample(nrow(X)), ]
        s2 <- kits_subj(Xp, parms)
        m <- match(s0$visit_id, s2$visit_id)
        list(diff = max(mad_(s0$theta, s2$theta[m]), mad_(s0$se, s2$se[m]), mad_(s0$raw, s2$raw[m])))
      })
check("kits", "kits_subj", "R3",
      "With all items answered (adding a zero and a perfect score), theta is finite, equal for equal raw scores and strictly increasing in raw.",
      "boundary", 1e-6, {
        top <- apply(X, 2, max)
        Xb <- rbind(X, zero = 0L, perfect = as.integer(top))
        s2 <- kits_subj(Xb, parms)
        by_raw <- split(s2$theta, s2$raw)
        spread <- max(vapply(by_raw, function(v) diff(range(v)), numeric(1)))
        med <- vapply(by_raw, mean, numeric(1))
        viol <- sum(diff(med) <= 0) + sum(!is.finite(s2$theta))
        list(diff = spread + viol,
             note = sprintf("raw 0..%d; %d non-increasing steps; within-raw spread %.2g",
                            max(s2$raw), sum(diff(med) <= 0), spread))
      })

# ---- kits_itemfit ----
f0 <- kits_itemfit(X, item)
check("kits", "kits_itemfit", "R1",
      "Permuting the persons leaves every item's n, pvalue, rir, infit and outfit unchanged.",
      "data_management", 1e-8, {
        f2 <- kits_itemfit(X[sample(nrow(X)), ], item)
        list(diff = max(mad_(f0$infit, f2$infit), mad_(f0$outfit, f2$outfit), mad_(f0$rir, f2$rir),
                        mad_(f0$pvalue, f2$pvalue), mad_(f0$n, f2$n)))
      })
check("kits", "kits_itemfit", "R2",
      "Duplicating every person (same item parameters) doubles n and leaves pvalue, infit and outfit (mean squares) unchanged.",
      "formula", 1e-8, {
        X2 <- rbind(X, X)
        rownames(X2) <- c(rownames(X), paste0(rownames(X), "_dup"))
        f2 <- kits_itemfit(X2, item)
        list(diff = max(mad_(f0$infit, f2$infit), mad_(f0$outfit, f2$outfit),
                        mad_(f0$pvalue, f2$pvalue), mad_(2 * f0$n, f2$n)),
             note = sprintf("rir %s vs %s (not part of the relation)",
                            format(round(f0$rir[1], 4)), format(round(f2$rir[1], 4))))
      })
check("kits", "kits_itemfit", "R3",
      "Adding a constant c = 2 to every beta leaves the conditional infit and outfit unchanged (the conditional probabilities given the raw score do not depend on the origin).",
      "formula", 1e-6, {
        p2 <- parms; p2$beta <- p2$beta + 2
        fa <- kits_itemfit(X, parms); fb <- kits_itemfit(X, p2)
        list(diff = max(mad_(fa$infit, fb$infit), mad_(fa$outfit, fb$outfit)))
      })

# ---- kits_subj_table ----
tab0 <- kits_subj_table(kits_subj(X, parms))
check("kits", "kits_subj_table", "R1",
      "Adding c = -0.7 to every beta adds c to the theta of every raw score in the table; se, n and pct are unchanged.",
      "formula", 1e-5, {
        p2 <- parms; p2$beta <- p2$beta - 0.7
        t2 <- kits_subj_table(kits_subj(X, p2))
        list(diff = max(mad_(t2$theta + 0.7, tab0$theta), mad_(t2$se, tab0$se), mad_(t2$n, tab0$n),
                        mad_(t2$pct, tab0$pct)))
      })
check("kits", "kits_subj_table", "R2",
      "Duplicating every person doubles n of every raw score and leaves raw, theta, se, pct and cum_pct unchanged.",
      "data_management", 1e-8, {
        X2 <- rbind(X, X)
        rownames(X2) <- c(rownames(X), paste0(rownames(X), "_dup"))
        t2 <- kits_subj_table(kits_subj(X2, parms))
        list(diff = max(mad_(t2$theta, tab0$theta), mad_(t2$se, tab0$se), mad_(t2$n, 2 * tab0$n),
                        mad_(t2$pct, tab0$pct), mad_(t2$cum_pct, tab0$cum_pct), mad_(t2$raw, tab0$raw)))
      })
check("kits", "kits_subj_table", "R3",
      "Removing every person with raw score 4 (an empty raw-score category) leaves theta and se of every other raw score in the table unchanged.",
      "boundary", 1e-8, {
        s <- kits_subj(X, parms)
        keep <- s$visit_id[s$raw != 4]
        t2 <- kits_subj_table(kits_subj(X[keep, ], parms))
        common <- intersect(t2$raw, tab0$raw)
        a <- tab0[match(common, tab0$raw), ]; b <- t2[match(common, t2$raw), ]
        has4 <- 4 %in% t2$raw
        list(diff = max(mad_(a$theta, b$theta), mad_(a$se, b$se)),
             note = sprintf("raw 4 %s in the table after removing its persons (n = %s)",
                            if (has4) "kept" else "dropped",
                            if (has4) t2$n[t2$raw == 4] else "-"))
      })

# ---- kits_linking ----
L_oy <- kits_linking(item_old, item_young)
L_yo <- kits_linking(item_young, item_old)
check("kits", "kits_linking", "R1",
      "Linking a calibration to a copy of itself (same data, another scale label) gives slope 1 and intercept 0 with no point dropped.",
      "formula", 1e-8, {
        copy <- kits_item(young, scale = "young copy")
        L <- kits_linking(copy, item_young)
        list(diff = max(abs(L$slope - 1), abs(L$intercept), nrow(L$dropped %||% data.frame())),
             note = sprintf("n = %d points", L$n))
      })
check("kits", "kits_linking", "R2",
      "Linking B to A is the inverse of linking A to B: slope_BA = 1/slope_AB and intercept_BA = -intercept_AB/slope_AB.",
      "formula", 1e-8, {
        list(diff = max(abs(L_yo$slope - 1 / L_oy$slope),
                        abs(L_yo$intercept + L_oy$intercept / L_oy$slope),
                        abs(nrow(L_yo$dropped %||% data.frame()) - nrow(L_oy$dropped %||% data.frame()))),
             note = sprintf("slope_AB %.4f, intercept_AB %.4f", L_oy$slope, L_oy$intercept))
      })
check("kits", "kits_linking", "R3",
      "Adding c = 1 to the target thresholds adds c to the intercept and leaves the slope and the bootstrap linking errors (same seed) unchanged.",
      "interval", 1e-8, {
        cy <- coef(item_young); cy$thr <- cy$thr + 1; cy$beta <- cy$beta + 1
        La <- kits_linking(item_old, item_young, n_boot = 200, seed = 1)
        Lb <- kits_linking(item_old, cy, n_boot = 200, seed = 1)
        list(diff = max(abs(Lb$intercept - La$intercept - 1), abs(Lb$slope - La$slope),
                        abs(Lb$intercept_error - La$intercept_error), abs(Lb$slope_error - La$slope_error)),
             note = sprintf("intercept_error %.4f, slope_error %.4f", La$intercept_error, La$slope_error))
      })

# ---- kits_link_line ----
pts0 <- kits_link_points(item_old, item_young)
line0 <- kits_link_line(kits_link_screen(pts0))
check("kits", "kits_link_line", "R1",
      "Transforming the target values of the points by to' = 2 * to + 3 gives slope' = 2 * slope and intercept' = 2 * intercept + 3.",
      "formula", 1e-8, {
        p <- pts0; p$to <- 2 * p$to + 3
        l <- kits_link_line(kits_link_screen(p))
        list(diff = max(abs(l$slope - 2 * line0$slope), abs(l$intercept - (2 * line0$intercept + 3))))
      })
check("kits", "kits_link_line", "R2",
      "Reversing the row order of the points leaves the line (intercept, slope) and the set of dropped points unchanged.",
      "data_management", 1e-10, {
        p <- pts0[rev(seq_len(nrow(pts0))), ]
        attr(p, "link") <- attr(pts0, "link")
        l <- kits_link_line(kits_link_screen(p))
        list(diff = max(abs(l$slope - line0$slope), abs(l$intercept - line0$intercept),
                        mis_(sort(l$points$id[l$points$dropped]), sort(line0$points$id[line0$points$dropped]))))
      })
check("kits", "kits_link_line", "R3",
      "Points that lie exactly on a line (to = 1.5 * from - 0.5, zero residuals) give that line back with no point dropped.",
      "boundary", 1e-8, {
        p <- pts0; p$to <- 1.5 * p$from - 0.5
        l <- kits_link_line(kits_link_screen(p))
        nd <- sum(l$points$dropped %in% TRUE)
        list(diff = max(abs(l$slope - 1.5), abs(l$intercept + 0.5)) + nd,
             note = sprintf("%d point(s) dropped", nd))
      })

# ---- kits_convert ----
s_old <- kits_subj(old, item_old)
check("kits", "kits_convert", "R1",
      "Converting with link A->B and then B->A (the inverse link) returns the original theta and se.",
      "formula", 1e-8, {
        back <- kits_convert(s_old, L_oy, L_yo)
        list(diff = max(mad_(back$theta, s_old$theta), mad_(back$se, s_old$se)),
             note = sprintf("scale after round trip: %s", attr(back, "scale")))
      })
check("kits", "kits_convert", "R2",
      "Doubling the input se doubles the converted se and leaves the converted theta unchanged.",
      "interval", 1e-10, {
        d1 <- data.frame(theta = s_old$theta, se = s_old$se)
        d2 <- data.frame(theta = s_old$theta, se = 2 * s_old$se)
        c1 <- kits_convert(d1, L_oy, from = "old"); c2 <- kits_convert(d2, L_oy, from = "old")
        list(diff = max(mad_(c2$se, 2 * c1$se), mad_(c2$theta, c1$theta)))
      })
check("kits", "kits_convert", "R3",
      "Setting some theta to NA gives NA for exactly those values and leaves the other converted values unchanged.",
      "boundary", 1e-12, {
        v <- s_old$theta[1:50]
        v2 <- v; v2[c(3, 17, 40)] <- NA
        c1 <- kits_convert(v, L_oy, from = "old"); c2 <- kits_convert(v2, L_oy, from = "old")
        ok_na <- identical(which(is.na(c2)), c(3L, 17L, 40L))
        list(diff = mad_(c1[!is.na(v2)], c2[!is.na(v2)]) + (!ok_na))
      })

# ---- kits_drift ----
bd <- list(a1 = c(-1, 0), a2 = c(0, 1), a3 = 0.5, a4 = -0.5, a5 = c(-0.5, 0.5), a6 = 1.5,
           a7 = c(-1, 1), a8 = 0)
set.seed(3)
d_old <- kits_sim(seq(-3, 3, length.out = 400), bd, seed = 1)
it_old <- kits_item(d_old, scale = "ref")
d_new <- kits_sim(seq(-2, 4, length.out = 400), modifyList(bd, list(a3 = 2)), prefix = "n", seed = 2)
ref0 <- as.data.frame(coef(it_old))[c("item_id", "item_score", "beta")]
attr(ref0, "scale") <- "ref"
dr0 <- kits_drift(d_new, ref0)
check("kits", "kits_drift", "R1",
      "Adding c = 0.8 to every reference beta adds c to the intercept, leaves the slope and the drift flags unchanged, and adds c to the suggested fixed betas.",
      "formula", 1e-6, {
        r2 <- ref0; r2$beta <- r2$beta + 0.8
        dr <- kits_drift(d_new, r2)
        list(diff = max(abs(dr$intercept - dr0$intercept - 0.8), abs(dr$slope - dr0$slope),
                        mis_(dr$items$drift, dr0$items$drift), mad_(dr$fix$beta - 0.8, dr0$fix$beta)),
             note = sprintf("drifted: %s", paste(dr0$items$item_id[dr0$items$drift %in% TRUE], collapse = ",")))
      })
check("kits", "kits_drift", "R2",
      "Permuting the persons of the new data leaves the line, the residuals and the drift flags unchanged.",
      "data_management", 1e-6, {
        dr <- kits_drift(d_new[sample(nrow(d_new)), ], ref0)
        list(diff = max(abs(dr$intercept - dr0$intercept), abs(dr$slope - dr0$slope),
                        mis_(dr$items$drift, dr0$items$drift),
                        mad_(dr$items$max_abs_resid, dr0$items$max_abs_resid)))
      })
check("kits", "kits_drift", "R3",
      "Renaming every item the same way in the new data and in the reference (a -> zz_a) only renames the items in the result.",
      "variable_mapping", 1e-6, {
        dn <- d_new; colnames(dn) <- paste0("zz_", colnames(dn))
        r2 <- ref0; r2$item_id <- paste0("zz_", r2$item_id)
        dr <- kits_drift(dn, r2)
        m <- match(paste0("zz_", dr0$items$item_id), dr$items$item_id)
        list(diff = max(abs(dr$intercept - dr0$intercept), abs(dr$slope - dr0$slope),
                        mis_(dr$items$drift[m], dr0$items$drift), sum(is.na(m)),
                        mad_(dr$items$max_abs_resid[m], dr0$items$max_abs_resid)))
      })

# ---- kits_norms ----
set.seed(1)
age <- runif(600, 3, 36)
D <- 20 + 15 * log(age) + rnorm(600, 0, 3)
ages <- seq(3, 36, by = 3)
pcols <- paste0("P", NORM_PCT)
norm0 <- kits_norms(D, age, ages = ages, degrees = c(3, 2, 1, 1))
check("kits", "kits_norms", "R1",
      "Adding c = 10 to every score adds c to mu and to every percentile and leaves sigma, epsilon and delta unchanged.",
      "formula", 1e-4, {
        n2 <- kits_norms(D + 10, age, ages = ages, degrees = c(3, 2, 1, 1))
        list(diff = max(mad_(as.matrix(n2[pcols]) - 10, as.matrix(norm0[pcols])), mad_(n2$mu - 10, norm0$mu),
                        mad_(n2$sigma, norm0$sigma), mad_(n2$epsilon, norm0$epsilon), mad_(n2$delta, norm0$delta)),
             note = sprintf("-logL %.6f vs %.6f", norm0$neg_loglik[1], n2$neg_loglik[1]))
      })
check("kits", "kits_norms", "R2",
      "Multiplying every score by a = 2 multiplies mu, sigma and every percentile by a and leaves epsilon and delta unchanged.",
      "formula", 1e-3, {
        n2 <- kits_norms(2 * D, age, ages = ages, degrees = c(3, 2, 1, 1))
        list(diff = max(mad_(as.matrix(n2[pcols]) / 2, as.matrix(norm0[pcols])), mad_(n2$mu / 2, norm0$mu),
                        mad_(n2$sigma / 2, norm0$sigma), mad_(n2$epsilon, norm0$epsilon), mad_(n2$delta, norm0$delta)),
             note = "tolerance on the original score scale")
      })
check("kits", "kits_norms", "R3",
      "Adding 50 person-waves with ages outside ages +/- pad (60 to 80 months) leaves the norm table unchanged.",
      "boundary", 1e-8, {
        set.seed(5)
        n2 <- kits_norms(c(D, rnorm(50, 90, 5)), c(age, runif(50, 60, 80)), ages = ages, degrees = c(3, 2, 1, 1))
        list(diff = max(mad_(as.matrix(n2[pcols]), as.matrix(norm0[pcols])), mad_(n2$n, norm0$n)))
      })

# ---- kits_norm_z ----
check("kits", "kits_norm_z", "R1",
      "The z of the table's percentile score P_p at a table age is qnorm(p/100) (table -> z round trip).",
      "formula", 1e-6, {
        grid <- expand.grid(i = seq_len(nrow(norm0)), j = seq_along(pcols))
        dd <- mapply(function(i, j) norm0[[pcols[j]]][i], grid$i, grid$j)
        z <- kits_norm_z(dd, age_m = norm0$age_m[grid$i], norm0)
        list(diff = mad_(z, qnorm(NORM_PCT[grid$j] / 100)))
      })
check("kits", "kits_norm_z", "R2",
      "At a fixed age, a larger score gives a strictly larger z (z is monotone in the score).",
      "formula", 0, {
        dd <- seq(min(D) - 10, max(D) + 10, length.out = 400)
        viol <- sum(vapply(c(4.5, 12, 24, 35), function(a) {
          z <- kits_norm_z(dd, age_m = rep(a, length(dd)), norm0)
          sum(diff(z) <= 0 | is.na(diff(z)))
        }, numeric(1)))
        list(diff = viol, note = "count of non-increasing steps over 4 ages x 400 scores")
      })
check("kits", "kits_norm_z", "R3",
      "Ages outside the norm range give NA, while the end ages of the range (3 and 36 months) give finite z.",
      "boundary", 0, {
        z <- kits_norm_z(rep(60, 4), age_m = c(2.5, 3, 36, 36.5), norm0)
        list(diff = sum(!is.na(z[c(1, 4)])) + sum(!is.finite(z[2:3])),
             note = paste("z =", paste(format(round(z, 3)), collapse = ", ")))
      })

# =============================================================================================
# kitsUI
# =============================================================================================

# ---- kitsui_round: round 1 (M03 lan 3 months, free) then round 2 (6 months, fixed bank) ----
r1 <- suppressMessages(kitsui_round(kitsui_demo("M03", 3, "lan"), kitsui_fixed_empty(), "3"))
df6 <- kitsui_demo("M03", 6, "lan")
round2 <- function(df) suppressMessages(kitsui_round(df, r1$fixed, "6"))
r2_0 <- round2(df6)
bank_of <- function(r) as.data.frame(r$fixed$bank) |> arrange(scale, item_id, item_score)
log_of <- function(r) as.data.frame(r$log)[c("scale", "item_id", "check")] |> arrange(scale, item_id, check)
round_diff <- function(a, b) {
  ba <- bank_of(a); bb <- bank_of(b); la <- log_of(a); lb <- log_of(b)
  max(mis_(paste(ba$item_id, ba$item_score), paste(bb$item_id, bb$item_score)),
      mad_(ba$beta, bb$beta), mad_(ba$beta_se, bb$beta_se),
      mis_(paste(la$scale, la$item_id, la$check), paste(lb$scale, lb$item_id, lb$check)))
}
check("kitsUI", "kitsui_round", "R1",
      "Shuffling the rows of the long data leaves the bank (steps, beta, beta_se) and the checks log unchanged.",
      "data_management", 1e-6, {
        r <- round2(df6[sample(nrow(df6)), ])
        list(diff = round_diff(r, r2_0),
             note = sprintf("bank %d steps; %d log rows", nrow(bank_of(r2_0)), nrow(log_of(r2_0))))
      })
check("kitsUI", "kitsui_round", "R2",
      "Renaming the visit_id and subj_id values one-to-one leaves the bank and the checks log unchanged.",
      "variable_mapping", 1e-6, {
        d <- df6
        d$visit_id <- paste0("V", match(d$visit_id, sample(unique(d$visit_id))))
        d$subj_id <- paste0("S", match(d$subj_id, sample(unique(d$subj_id))))
        list(diff = round_diff(round2(d), r2_0))
      })
check("kitsUI", "kitsui_round", "R3",
      "Adding rows for a new item whose score is NA for every visit leaves the bank and the checks log unchanged.",
      "boundary", 1e-8, {
        extra <- df6[df6$item_id == df6$item_id[1], ]
        extra$item_id <- "lanzz99"; extra$item_score <- NA_integer_
        r <- round2(bind_rows(df6, extra))
        list(diff = round_diff(r, r2_0),
             note = sprintf("lanzz99 in bank: %s", "lanzz99" %in% r$fixed$bank$item_id))
      })

# ---- kitsui_cap (hand-made matrix and bank) ----
Xc <- cbind(i1 = c(0, 1, 2, 3, 4, NA, 2), i2 = c(0, 1, 1, 3, NA, 0, 1), i3 = c(0, 2, 5, 1, 1, 0, 3),
            i4 = c(0, 1, 2, 3, 3, 2, 1))
rownames(Xc) <- paste0("v", 1:7)
bank_c <- data.frame(item_id = c("i1", "i2", "i2", "i4"), item_score = c(1, 1, 2, 1))
cap0 <- kitsui_cap(Xc, bank_c, no_new = "i4")
check("kitsUI", "kitsui_cap", "R1",
      "Capping is idempotent: capping the capped matrix again changes no cell and logs nothing.",
      "formula", 0, {
        again <- kitsui_cap(cap0$X, bank_c, no_new = "i4")
        list(diff = mis_(again$X, cap0$X) + nrow(again$log),
             note = sprintf("first pass merged %d item(s)", nrow(cap0$log)))
      })
check("kitsUI", "kitsui_cap", "R2",
      "Permuting the columns (items) gives the same capped values for each item and the same log rows.",
      "data_management", 0, {
        p <- kitsui_cap(Xc[, c(4, 2, 3, 1)], bank_c, no_new = "i4")
        lp <- p$log[order(p$log$item_id), ]; l0 <- cap0$log[order(cap0$log$item_id), ]
        list(diff = mis_(p$X[, colnames(Xc)], cap0$X) + mis_(lp$detail_en, l0$detail_en))
      })
check("kitsUI", "kitsui_cap", "R3",
      "NA cells stay NA, an item not in the bank is untouched, and an item in no_new is capped exactly at its bank top step.",
      "boundary", 0, {
        x <- cap0$X
        list(diff = mis_(is.na(x), is.na(Xc)) + mis_(x[, "i3"], Xc[, "i3"]) +
               sum(x[, "i4"] != pmin(Xc[, "i4"], 1)),
             note = sprintf("i1 capped at %d, i2 at %d", max(x[, "i1"], na.rm = TRUE), max(x[, "i2"], na.rm = TRUE)))
      })

# ---- kitsui_category_problems (hand-made long data) ----
set.seed(11)
cat_df <- mutate(.after = cohort, wave_m = 3, bind_rows(
  tibble(domain = "lan", cohort = "M03", visit_id = paste0("v", 1:30), item_id = "ok1",
         item_score = rep(0:2, 10)),
  tibble(domain = "lan", cohort = "M03", visit_id = paste0("v", 1:30), item_id = "ok2",
         item_score = rep(0:1, 15)),
  tibble(domain = "lan", cohort = "M03", visit_id = paste0("v", 1:30), item_id = "gap",
         item_score = rep(c(0, 2), 15)),
  tibble(domain = "motor", cohort = "M03", visit_id = paste0("v", 1:30), item_id = "nozero",
         item_score = rep(1:2, 15))
))
cp0 <- kitsui_category_problems(cat_df)
key_cp <- function(x) paste(x$scale, x$item_id, x$problem, x$detail_en)
check("kitsUI", "kitsui_category_problems", "R1",
      "Shuffling the rows of the data leaves the list of problem items and their details unchanged.",
      "data_management", 0, {
        cp <- kitsui_category_problems(cat_df[sample(nrow(cat_df)), ])
        list(diff = mis_(key_cp(cp), key_cp(cp0)), note = paste(cp0$item_id, cp0$problem, sep = ": ", collapse = "; "))
      })
check("kitsUI", "kitsui_category_problems", "R2",
      "Adding 1 to every score of a clean item (ok1, 0-2 -> 1-3) adds exactly one problem, 'no 0 score', for that item and leaves the other rows unchanged.",
      "formula", 0, {
        d <- cat_df; d$item_score[d$item_id == "ok1"] <- d$item_score[d$item_id == "ok1"] + 1
        cp <- kitsui_category_problems(d)
        new <- cp[cp$item_id == "ok1", ]
        list(diff = (nrow(new) != 1) + (!identical(new$problem, "no 0 score")) +
               mis_(key_cp(cp[cp$item_id != "ok1", ]), key_cp(cp0)))
      })
check("kitsUI", "kitsui_category_problems", "R3",
      "Emptying the middle category of a clean item (no one scores 1 on ok1) adds a 'score gap' for that item; adding NA scores changes nothing.",
      "boundary", 0, {
        d <- cat_df[!(cat_df$item_id == "ok1" & cat_df$item_score == 1), ]
        na_rows <- tibble(domain = "lan", cohort = "M03", visit_id = "v99", item_id = c("ok2", "gap"),
                          item_score = NA_real_)
        cp <- kitsui_category_problems(bind_rows(d, na_rows))
        new <- cp[cp$item_id == "ok1", ]
        list(diff = (nrow(new) != 1) + (!identical(new$problem, "score gap")) +
               mis_(key_cp(cp[cp$item_id != "ok1", ]), key_cp(cp0)),
             note = if (nrow(new) == 1) new$detail_en else "")
      })

# ---- kitsui_score (lan M03 + M36, 36 and 48 months, internal link M36 -> M03) ----
df_sc <- kitsui_demo(waves = c(36, 48), domains = "lan")
r_sc <- suppressMessages(kitsui_round(df_sc, kitsui_fixed_empty(), "1"))
fx_sc <- suppressMessages(kitsui_link_internal(r_sc$fixed, "lan")$fixed)
fresh <- function(r) { r$memo <- new.env(parent = emptyenv()); r }
sc0 <- kitsui_score(fresh(r_sc), df_sc, fx_sc)
check("kitsUI", "kitsui_score", "R1",
      "Shuffling the rows of each calibrated response matrix leaves each visit's ability, ability_se and converted theta unchanged.",
      "data_management", 1e-8, {
        r <- fresh(r_sc)
        r$data <- lapply(r$data, function(m) m[sample(nrow(m)), , drop = FALSE])
        sc <- kitsui_score(r, df_sc, fx_sc)
        m <- match(sc0$scores$visit_id, sc$scores$visit_id)
        a <- sc0$subj[["lan M36"]]; b <- sc$subj[["lan M36"]]; mb <- match(a$visit_id, b$visit_id)
        list(diff = max(mad_(sc0$scores$ability, sc$scores$ability[m]),
                        mad_(sc0$scores$ability_se, sc$scores$ability_se[m]),
                        mad_(a$theta, b$theta[mb]), mad_(a$se, b$se[mb])),
             note = sprintf("%d score rows", nrow(sc0$scores)))
      })
check("kitsUI", "kitsui_score", "R2",
      "Adding c = 0.5 to the 'to' values of the stored internal-link points adds c to every converted M36 theta and leaves ability, converted se and the M03 scores unchanged.",
      "formula", 1e-8, {
        fx <- fx_sc
        k <- fx$links$kind == "internal"
        fx$links$to[k] <- fx$links$to[k] + 0.5
        sc <- kitsui_score(fresh(r_sc), df_sc, fx)
        a <- sc0$subj[["lan M36"]]; b <- sc$subj[["lan M36"]]
        list(diff = max(mad_(b$theta - 0.5, a$theta), mad_(b$se, a$se),
                        mad_(sc$scores$ability, sc0$scores$ability),
                        mad_(sc$subj[["lan M03"]]$theta, sc0$subj[["lan M03"]]$theta)))
      })
check("kitsUI", "kitsui_score", "R3",
      "Adding a visit that scores 0 on every item it answered gives it a finite ability below every other visit with the same item pattern and leaves the other visits unchanged.",
      "boundary", 1e-8, {
        r <- fresh(r_sc)
        m <- r$data[["lan M36"]]
        z <- m[1, , drop = FALSE]; z[!is.na(z)] <- 0L; rownames(z) <- "M36_zero_visit"
        r$data[["lan M36"]] <- rbind(m, z)
        persons <- bind_rows(kitsui_persons(df_sc),
                             tibble(visit_id = "M36_zero_visit", subj_id = "zero", wave_m = 36,
                                    age_m = 36, sex = "girl", cohort = "M36"))
        sc <- kitsui_score(r, df_sc, fx_sc, persons = persons)
        own <- sc$own[["lan M36"]]
        zr <- own[own$visit_id == "M36_zero_visit", ]
        same <- own[own$pattern_id == zr$pattern_id & own$visit_id != "M36_zero_visit", ]
        mm <- match(sc0$scores$visit_id, sc$scores$visit_id)
        bad <- (!is.finite(zr$theta)) + sum(same$theta <= zr$theta)
        list(diff = bad + mad_(sc0$scores$ability, sc$scores$ability[mm]),
             note = sprintf("zero visit ability %.3f; %d other visits with its pattern", zr$theta, nrow(same)))
      })

# =============================================================================================
# kitJoin
# =============================================================================================

# ---- replace_na_codes ----
na_df <- tibble(id = c(1, 2, 3, 4, 5, 6), q1 = c(1, 98, 3, 99, 2, NA), q2 = c(97, 4, 99, 5, 98, 1),
                note = c("a", "98", "b", "99", "c", "d"), age = c(98, 12, 24, 99, 36, 48))
codes <- c(97, 98, 99)
rn0 <- replace_na_codes(na_df, codes, exclude = c("id", "age"))
check("kitJoin", "replace_na_codes", "R1",
      "Replacing the missing codes is idempotent: a second pass changes no cell and reports no replacement.",
      "data_management", 0, {
        again <- replace_na_codes(rn0$data, codes, exclude = c("id", "age"))
        list(diff = sum(vapply(names(na_df), function(cl) mis_(again$data[[cl]], rn0$data[[cl]]), numeric(1))) +
               NROW(again$detail))
      })
check("kitJoin", "replace_na_codes", "R2",
      "The order of the codes does not matter: codes 99, 97, 98 give the same data and the same counts per column.",
      "data_management", 0, {
        rv <- replace_na_codes(na_df, rev(codes), exclude = c("id", "age"))
        tot <- function(d) d[[ncol(d)]]
        list(diff = sum(vapply(names(na_df), function(cl) mis_(rv$data[[cl]], rn0$data[[cl]]), numeric(1))) +
               mis_(tot(rv$detail), tot(rn0$detail)))
      })
check("kitJoin", "replace_na_codes", "R3",
      "Values not in the code list, NA cells, excluded columns and text columns (match_text = FALSE) are untouched; the number of new NA equals the number of code cells.",
      "boundary", 0, {
        d <- rn0$data
        nc <- c("q1", "q2")
        keep <- sum(vapply(nc, function(cl) mis_(d[[cl]][!na_df[[cl]] %in% codes], na_df[[cl]][!na_df[[cl]] %in% codes]), numeric(1)))
        n_new <- sum(is.na(as.matrix(d[nc]))) - sum(is.na(as.matrix(na_df[nc])))
        n_codes <- sum(as.matrix(na_df[nc]) %in% codes)
        list(diff = keep + abs(n_new - n_codes) + mis_(d$age, na_df$age) + mis_(d$note, na_df$note) + mis_(d$id, na_df$id),
             note = sprintf("%d code cells replaced", n_new))
      })

# ---- join_waves ----
w1 <- tibble(id = c(1, 2, 3, 4, 6), score = c(10, 20, 30, 40, 60), sex = c("b", "g", "b", "g", "b"))
w2 <- tibble(id = c(2, 3, 5, 6, 7), score = c(21, 31, 51, 61, 71))
w3 <- tibble(id = c(1, 3, 6, 8), score = c(12, 32, 62, 82))
jw <- function(dfs, method = "full_join", labels = c("t1", "t2", "t3")) {
  suppressMessages(join_waves(dfs, c("a.csv", "b.csv", "c.csv"), labels, "id", method))$result |>
    arrange(id) |> as.data.frame()
}
j0 <- jw(list(w1, w2, w3))
check("kitJoin", "join_waves", "R1",
      "Shuffling the rows of every input file leaves the joined table (sorted by id) unchanged.",
      "data_management", 0, {
        j <- jw(lapply(list(w1, w2, w3), function(d) d[sample(nrow(d)), ]))
        list(diff = sum(vapply(names(j0), function(cl) mis_(j[[cl]], j0[[cl]]), numeric(1))) + abs(ncol(j) - ncol(j0)))
      })
check("kitJoin", "join_waves", "R2",
      "With unique ids, full_join has one row per id in the union, inner_join one per id in the intersection, left_join one per id of the first file.",
      "data_management", 0, {
        ids <- list(w1$id, w2$id, w3$id)
        n_full <- nrow(j0); n_inner <- nrow(jw(list(w1, w2, w3), "inner_join")); n_left <- nrow(jw(list(w1, w2, w3), "left_join"))
        list(diff = abs(n_full - length(Reduce(union, ids))) + abs(n_inner - length(Reduce(intersect, ids))) +
               abs(n_left - nrow(w1)),
             note = sprintf("full %d, inner %d, left %d", n_full, n_inner, n_left))
      })
check("kitJoin", "join_waves", "R3",
      "Renaming the wave labels (t1, t2, t3 -> A, B, C) only renames the suffixes; every value is unchanged.",
      "variable_mapping", 0, {
        j <- jw(list(w1, w2, w3), labels = c("A", "B", "C"))
        renamed <- sub("_A$", "_t1", sub("_B$", "_t2", sub("_C$", "_t3", names(j))))
        list(diff = mis_(renamed, names(j0)) +
               sum(vapply(seq_along(j0), function(k) mis_(j[[k]], j0[[k]]), numeric(1))))
      })

# ---- reshape_wider / reshape_longer ----
long0 <- tibble(id = rep(1:5, each = 3), wave = rep(c("t1", "t2", "t3"), 5),
                score = c(3, 5, 7, 2, 4, 6, 1, 1, 2, 8, 9, 10, 0, 5, 3))
wargs <- wider_args(id_cols = "id", names_from = "wave", values_from = "score")
largs <- function(drop = FALSE) longer_args(cols = c("t1", "t2", "t3"), names_to = "wave", values_to = "score",
                                            values_drop_na = drop)
srt <- function(d) as.data.frame(arrange(d, id, wave))
check("kitJoin", "reshape_wider/longer", "R1",
      "Long -> wide -> long returns the original long table (as a set of rows).",
      "data_management", 0, {
        back <- srt(reshape_longer(reshape_wider(long0, wargs)$result, largs())$result)
        a <- srt(long0)
        list(diff = mis_(back$id, a$id) + mis_(back$wave, a$wave) + mis_(back$score, a$score))
      })
check("kitJoin", "reshape_wider/longer", "R2",
      "Wide -> long -> wide returns the original wide table, also when the rows of the long table are shuffled.",
      "data_management", 0, {
        wide0 <- arrange(reshape_wider(long0, wargs)$result, id)
        lg <- reshape_longer(wide0, largs())$result
        wide1 <- arrange(reshape_wider(lg[sample(nrow(lg)), ], wargs)$result, id)
        val <- sum(vapply(names(wide0), function(cl) mis_(wide1[[cl]], wide0[[cl]]), numeric(1)))
        ord <- mis_(names(wide1), names(wide0))
        list(diff = val + ord,
             note = sprintf(paste0("cell values matched by column name: %d mismatches; column order %s vs %s ",
                                   "(%d positions differ: pivot_wider orders new columns by first appearance ",
                                   "in the long rows, names_sort = FALSE)"),
                            as.integer(val), paste(names(wide1), collapse = ","), paste(names(wide0), collapse = ","),
                            as.integer(ord)))
      })
check("kitJoin", "reshape_wider/longer", "R3",
      "A person with a missing wave (row removed) gets NA in that wide cell; wide -> long with values_drop_na returns exactly the non-missing rows.",
      "boundary", 0, {
        l2 <- long0[!(long0$id == 2 & long0$wave == "t3"), ]
        wd <- reshape_wider(l2, wargs)$result
        back <- srt(reshape_longer(wd, largs(drop = TRUE))$result)
        a <- srt(l2)
        list(diff = (!is.na(wd$t3[wd$id == 2])) + mis_(back$score, a$score) + abs(nrow(back) - nrow(l2)))
      })

# ---- stack_waves ----
s1 <- tibble(id = 1:3, x = c(1.5, 2, 3), y = c("a", "b", "c"))
s2 <- tibble(id = 4:5, x = c(4, 5), z = c(TRUE, FALSE))
s3 <- tibble(id = 6, x = 6, y = "f")
st <- function(dfs, labels) suppressMessages(stack_waves(dfs, paste0(labels, ".csv"), labels))
st0 <- st(list(s1, s2, s3), c("t1", "t2", "t3"))
check("kitJoin", "stack_waves", "R1",
      "The stacked table has as many rows as the files together and as many rows per wave as each file.",
      "data_management", 0, {
        r <- st0$result
        per <- as.integer(table(factor(r$wave, levels = c("t1", "t2", "t3"))))
        list(diff = abs(nrow(r) - 6) + sum(abs(per - c(3, 2, 1))))
      })
check("kitJoin", "stack_waves", "R2",
      "Stacking the files in another order gives the same rows (matched by id): same values and same wave labels.",
      "data_management", 0, {
        r1 <- as.data.frame(arrange(st0$result, id))
        r2 <- as.data.frame(arrange(st(list(s3, s1, s2), c("t3", "t1", "t2"))$result, id))
        list(diff = sum(vapply(names(r1), function(cl) mis_(r2[[cl]], r1[[cl]]), numeric(1))) +
               mis_(sort(names(r2)), sort(names(r1))))
      })
check("kitJoin", "stack_waves", "R3",
      "A column present in only some files is NA for the rows of the other files, and the other values are kept.",
      "boundary", 0, {
        r <- as.data.frame(arrange(st0$result, id))
        list(diff = sum(!is.na(r$z[r$id %in% c(1:3, 6)])) + sum(!is.na(r$y[r$id %in% 4:5])) +
               mis_(r$x, c(1.5, 2, 3, 4, 5, 6)) + mis_(r$z[r$id %in% 4:5], c(TRUE, FALSE)))
      })

# ---- build_attrition ----
base <- tibble(id = c(1:10, NA), x = 1:11)
follow <- tibble(id = c(2, 3, 5, 8, 9, 12))
at0 <- build_attrition(base, follow, "id")
check("kitJoin", "build_attrition", "R1",
      "Retained + lost + unmatched (NA id) equals the number of baseline rows, and retained equals the number of baseline ids found in the follow-up.",
      "formula", 0, {
        f <- at0$result$attrition
        list(diff = abs(sum(f == 0, na.rm = TRUE) + sum(f == 1, na.rm = TRUE) + sum(is.na(f)) - nrow(base)) +
               abs(sum(f == 0, na.rm = TRUE) - length(intersect(na.omit(base$id), follow$id))),
             note = sprintf("retained %d, lost %d, NA %d", sum(f == 0, na.rm = TRUE), sum(f == 1, na.rm = TRUE), sum(is.na(f))))
      })
check("kitJoin", "build_attrition", "R2",
      "Shuffling and duplicating the follow-up rows leaves every baseline flag unchanged.",
      "data_management", 0, {
        f2 <- bind_rows(follow, follow)[sample(2 * nrow(follow)), ]
        list(diff = mis_(build_attrition(base, f2, "id")$result$attrition, at0$result$attrition))
      })
check("kitJoin", "build_attrition", "R3",
      "An empty follow-up (0 rows) flags every baseline row with an id as lost and keeps NA for the missing id.",
      "boundary", 0, {
        out <- build_attrition(base, follow[0, ], "id")
        list(diff = mis_(out$result$attrition, ifelse(is.na(base$id), NA_integer_, 1L)))
      })

# ---- kits_build (kits response file from wide data) ----
sim_wide <- function(ids, wave, wave_m, seed) {
  set.seed(seed)
  n <- length(ids)
  sc <- function() sample(1:5, n, replace = TRUE)
  tibble(release_id = ids, wave = wave, wave_m = wave_m, age_m = wave_m + 0.2,
         sex = rep(c("boy", "girl"), length.out = n),
         lana01 = sc(), lana02 = sc(), bodyaf01 = sc())
}
kb_dfs <- list(bind_rows(sim_wide(paste0("K", 1:6), "m03g01", 3, 1), sim_wide(paste0("K", 1:5), "m06g02", 6, 2)),
               sim_wide(paste0("J", 1:4), "m36g01", 36, 3))
kb_table <- tibble(item_id = c("lana01", "lana02", "bodyaf01"), domain = c("lan", "lan", "motor"))
kb_spec <- function(dfs, fun = NULL) {
  map <- kits_guess_map(unique(unlist(lapply(dfs, names))))
  cand <- kits_candidate_cols(dfs, kits_mapped_cols(map))
  s <- kits_settings_apply(kits_item_settings(dfs, cand$numeric), list(type = "table", data = kb_table))
  if (!is.null(fun)) s <- fun(s)
  kits_spec(lapply(c("M03", "M36"), function(x) list(type = "text", value = x)), map,
            kits_settings_items(s), kits_settings_undecided(s))
}
kb_long <- function(dfs, fun = NULL) {
  out <- suppressMessages(kits_build(dfs, c("a.csv", "b.csv"), kb_spec(dfs, fun)))
  if (length(out$problems) > 0) stop(paste(out$problems, collapse = " | "))
  path <- tempfile(fileext = ".csv.gz"); on.exit(unlink(path))
  write_kits_long_gz(prep = out$prep, file = path)
  readr::read_csv(path, col_types = "ccccddcic", na = "", progress = FALSE) |>
    arrange(visit_id, item_id) |> as.data.frame()
}
kl0 <- kb_long(kb_dfs)
check("kitJoin", "kits_build", "R1",
      "Shifting the scoring of every item by -1 (1-5 -> 0-4) lowers every item_score by exactly 1 and changes no other column.",
      "formula", 0, {
        kl <- kb_long(kb_dfs, function(s) kits_bulk_shift(s, s$column, -1))
        other <- setdiff(names(kl0), "item_score")
        list(diff = mis_(kl$item_score, kl0$item_score - 1L) +
               sum(vapply(other, function(cl) mis_(kl[[cl]], kl0[[cl]]), numeric(1))),
             note = sprintf("%d response rows", nrow(kl0)))
      })
check("kitJoin", "kits_build", "R2",
      "Shuffling the rows within each wide file leaves the long response file (sorted) unchanged.",
      "data_management", 0, {
        kl <- kb_long(lapply(kb_dfs, function(d) d[sample(nrow(d)), ]))
        list(diff = sum(vapply(names(kl0), function(cl) mis_(kl[[cl]], kl0[[cl]]), numeric(1))))
      })
check("kitJoin", "kits_build", "R3",
      "Setting some item cells to NA removes exactly those (visit, item) rows from the long file and leaves the other rows unchanged.",
      "boundary", 0, {
        d <- kb_dfs
        d[[1]]$lana02[c(2, 7)] <- NA; d[[2]]$bodyaf01[1] <- NA
        kl <- kb_long(d)
        k0 <- paste(kl0$visit_id, kl0$item_id); k1 <- paste(kl$visit_id, kl$item_id)
        gone <- setdiff(k0, k1)
        m <- match(k1, k0)
        list(diff = abs(length(gone) - 3) + abs(nrow(kl0) - nrow(kl) - 3) + sum(is.na(m)) +
               mis_(kl$item_score, kl0$item_score[m]),
             note = paste("removed:", paste(gone, collapse = "; ")))
      })

# ---- write results ----------------------------------------------------------------------------
res <- do.call(rbind, results)
write.csv(res, file.path(out_dir, "metamorphic_results.csv"), row.names = FALSE)
total <- round(as.numeric(difftime(Sys.time(), t_start, units = "secs")), 1)
cat(sprintf("\n%d functions x 3 relations = %d relations; %d PASS, %d FAIL; runtime %.1f s\n",
            length(unique(paste(res$package, res$`function`))), nrow(res), sum(res$pass), sum(!res$pass), total))
cat(sprintf("kits %s, kitsUI %s, kitJoin %s, R %s\n", packageVersion("kits"), packageVersion("kitsUI"),
            packageVersion("kitJoin"), getRversion()))
