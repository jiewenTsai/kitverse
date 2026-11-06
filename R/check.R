# Check whether this computer can run the KIT tools
#
# One item per line: ✔ fine, ✖ needs fixing, ! works but worth knowing. The last items
# really start each app (in a separate R, no browser), wait for the page, then stop it.

#' Check whether this computer can run the KIT tools
#'
#' One line per item: the R version, whether the package library is writable, whether every
#' package is installed and new enough, whether the packages load, the Linux system libraries,
#' the temporary folder, and the internet connection used for fonts. Finally it really starts
#' kitsUI and kitJoin (in a separate R, without a browser) and checks that each page comes back.
#' Ask workshop participants to run it once beforehand and send a screenshot.
#'
#' @param apps `TRUE` to really start the apps (about 5–30 seconds each).
#' @param timeout How many seconds to wait for each app.
#' @return A data frame (invisibly): `item`, `status` (`"ok"`, `"fail"`, `"note"`), `detail`.
#' @examples
#' if (interactive()) kitverse_check()
#' @export
kitverse_check <- function(apps = TRUE, timeout = 120) {
  res <- ktv_check_items()
  if (apps && all(res$status[res$item %in% c("Package versions", "Package loading")] == "ok")) {
    for (app in ktv_apps()) {
      res <- rbind(res, ktv_check_app(app, timeout = timeout))
    }
  } else if (apps) {
    res <- rbind(res, ktv_item("Start apps", "fail",
                               "packages have problems; run kitverse::kitverse_update() first"))
  }
  ktv_print_check(res)
  invisible(res)
}

#' The two apps: name, package, launcher
#' @noRd
ktv_apps <- function() {
  list(
    list(name = "kitsUI", pkg = "kitsUI", run = "run_kitsui"),
    list(name = "kitJoin", pkg = "kitJoin", run = "run_kitjoin")
  )
}

#' One row of check results
#' @noRd
ktv_item <- function(item, status, detail) {
  data.frame(item = item, status = status, detail = detail, stringsAsFactors = FALSE)
}

#' The checks that do not start an app
#' @noRd
ktv_check_items <- function(req = kitverse_requirements()) {
  out <- list()
  # R: the packages need 4.1 or later; on Windows, R uses UTF-8 everywhere only from 4.2
  # (Chinese file names and column names)
  rv <- getRversion()
  out[[length(out) + 1]] <- if (rv < "4.1.0") {
    ktv_item("R", "fail", paste0(rv, ": too old; install the latest R from https://cran.r-project.org"))
  } else if (.Platform$OS.type == "windows" && rv < "4.2.0") {
    ktv_item("R", "note", paste0(rv, ": works, but Chinese file names may break; the latest R is recommended"))
  } else {
    rel <- ktv_r_releases()
    if (!is.null(rel) && !ktv_r_supported(rv, rel[["oldrel"]])) {
      ktv_item("R", "note", paste0(rv, ": older than CRAN's previous release (", rel[["oldrel"]],
                                   "), so updates have no pre-built packages; install the latest R ",
                                   "(on Windows: paste the install line again)"))
    } else {
      ktv_item("R", "ok", as.character(rv))
    }
  }

  lib <- .libPaths()[1]
  out[[length(out) + 1]] <- if (file.access(lib, 2) == 0) {
    ktv_item("Package library", "ok", lib)
  } else {
    ktv_item("Package library", "fail",
             paste0(lib, ": not writable; kitverse::kitverse_update() creates a personal library"))
  }

  # Whether the KIT packages are the current release (what the workshop slides show)
  out[[length(out) + 1]] <- ktv_check_release(kitverse_release())

  bad <- req[!req$ok, , drop = FALSE]
  out[[length(out) + 1]] <- if (nrow(bad) == 0) {
    ktv_item("Package versions", "ok", paste0("all ", nrow(req), " packages installed and new enough"))
  } else {
    ktv_item("Package versions", "fail",
             paste0(paste0(bad$pkg, " ", bad$why, collapse = "; "),
                    "\n    \u2192 run kitverse::kitverse_update()"))
  }

  # Load the core packages in a separate R: a failed load here would leave this session broken
  main <- ktv_core()
  out[[length(out) + 1]] <- if (nrow(bad) > 0) {
    ktv_item("Package loading", "fail", "fix the package versions above first")
  } else {
    err <- ktv_try_load(main)
    if (length(err) == 0) {
      ktv_item("Package loading", "ok",
               paste(main, vapply(main, ktv_installed_version, ""), collapse = ", "))
    } else {
      ktv_item("Package loading", "fail", paste(err, collapse = "\n    "))
    }
  }

  # Updated while loaded in this R session: only a restart of R helps
  stale <- ktv_stale_loaded(req$pkg)
  if (nrow(stale) > 0) {
    out[[length(out) + 1]] <- ktv_item("This R session", "fail", paste0(
      paste0(stale$pkg, " ", stale$loaded, " is loaded but ", stale$installed, " is installed",
             collapse = "; "),
      "\n    \u2192 restart R (in RStudio: Session > Restart R)"))
  }

  # Linux: system libraries the compiled packages need (for example fs needs libuv.so.1).
  # Without them the packages still load, and the app fails only when it draws the page.
  if (Sys.info()[["sysname"]] == "Linux") {
    miss <- ktv_missing_syslibs(req$pkg)
    out[[length(out) + 1]] <- if (length(miss) == 0) {
      ktv_item("System libraries", "ok", "everything the packages need is there")
    } else {
      ktv_item("System libraries", "fail", paste0(
        "missing ", paste(names(miss), collapse = ", "), " (needed by ",
        paste(unique(unlist(miss)), collapse = ", "), ")\n    \u2192 in a terminal: sudo apt install ",
        paste(ktv_apt_name(miss), collapse = " ")))
    }
  }

  # Pandoc: kitsUI's plot downloads (one html file) need it
  out[[length(out) + 1]] <- if (ktv_pandoc_found()) {
    ktv_item("Pandoc", "ok", ktv_pandoc_dir())
  } else {
    ktv_item("Pandoc", "fail",
             "not found: plots cannot be downloaded\n    \u2192 run kitverse::kitverse_pandoc()")
  }

  # Saving every kind of file the apps offer, in a separate R
  if (nrow(bad) == 0) out[[length(out) + 1]] <- ktv_check_saving()

  # Optional: kits::kits_save_plot(png = ) takes a browser screenshot (not used by the apps)
  out[[length(out) + 1]] <- if (nzchar(system.file(package = "webshot2"))) {
    ktv_item("PNG plots (optional)", "ok", "webshot2 installed")
  } else {
    ktv_item("PNG plots (optional)", "note",
             "kits_save_plot(png = ) also needs webshot2 and Chrome; the apps do not use it")
  }

  tmp <- tempdir()
  probe <- tempfile("kitverse-", tmpdir = tmp)
  ok_tmp <- tryCatch({ writeLines("ok", probe); unlink(probe); TRUE }, error = function(e) FALSE,
                     warning = function(w) FALSE)
  out[[length(out) + 1]] <- if (!ok_tmp) {
    ktv_item("Temporary folder", "fail",
             paste0(tmp, ": not writable (uploaded files and results are kept here)"))
  } else if (.Platform$OS.type == "windows" && grepl("[^\\x01-\\x7F]", tmp, perl = TRUE)) {
    ktv_item("Temporary folder", "note",
             paste0(tmp, ": the path has non-ASCII characters; tell the assistants if uploads or downloads fail"))
  } else {
    ktv_item("Temporary folder", "ok", tmp)
  }

  out[[length(out) + 1]] <- if (ktv_online("https://fonts.googleapis.com/css2?family=Chiron+GoRound+TC")) {
    ktv_item("Internet (fonts)", "ok", "Google Fonts reachable")
  } else {
    ktv_item("Internet (fonts)", "note", "Google Fonts not reachable: the apps work, with the computer's own fonts")
  }
  do.call(rbind, out)
}

#' Linux: system libraries that cannot be found (ldd on each package's .so files)
#'
#' Returns a named list: names are the missing libraries (for example `libuv.so.1`),
#' values are the packages that need them.
#' @noRd
ktv_missing_syslibs <- function(pkgs) {
  if (!nzchar(Sys.which("ldd"))) return(list())
  miss <- list()
  for (p in pkgs) {
    dir <- system.file("libs", package = p)
    if (!nzchar(dir)) next
    for (so in list.files(dir, pattern = "\\.so$", full.names = TRUE, recursive = TRUE)) {
      out <- suppressWarnings(system2("ldd", shQuote(so), stdout = TRUE, stderr = TRUE))
      lost <- sub("^\\s*(\\S+)\\s*=>\\s*not found.*$", "\\1", grep("not found", out, value = TRUE))
      for (l in lost) miss[[l]] <- union(miss[[l]], p)
    }
  }
  miss
}

#' System library file names to apt package names (unknown ones as they are)
#' @noRd
ktv_apt_name <- function(miss) {
  known <- c("libuv.so.1" = "libuv1", "libicuuc" = "libicu-dev", "libicui18n" = "libicu-dev",
             "libxml2.so.2" = "libxml2", "libcurl.so.4" = "libcurl4", "libssl.so.3" = "libssl3",
             "libfontconfig.so.1" = "libfontconfig1", "libfreetype.so.6" = "libfreetype6",
             "libpng16.so.16" = "libpng16-16", "libharfbuzz.so.0" = "libharfbuzz0b",
             "libfribidi.so.0" = "libfribidi0", "libgfortran.so.5" = "libgfortran5")
  out <- vapply(names(miss), function(l) {
    hit <- names(known)[startsWith(l, names(known))]
    if (length(hit)) known[[hit[1]]] else sub("\\.so.*$", "", l)
  }, character(1))
  unique(unname(out))
}

#' The useful lines of an app log: the errors (or the last lines when there are none)
#' @noRd
ktv_log_errors <- function(lines, n = 8) {
  lines <- lines[!grepl("^\\s*[0-9]+: ", lines)]  # skip the traceback
  err <- grep("error|Error|cannot|unable|not found", lines, value = TRUE)
  utils::tail(if (length(err)) err else lines, n)
}

#' Save one file of each kind the apps offer, in a separate R
#'
#' The plot is saved the way kitsUI does it (kits::kits_save_plot(), one html file); tables as
#' CSV (readr, as Excel reads it), csv.gz, SAV (haven) and zip (zip).
#' @noRd
ktv_check_saving <- function() {
  script <- tempfile("kitverse-save-", fileext = ".R")
  log <- tempfile("kitverse-save-", fileext = ".log")
  dir <- tempfile("kitverse-save-")
  on.exit(unlink(c(script, log, dir), recursive = TRUE), add = TRUE)
  writeLines(c(
    sprintf(".libPaths(%s)", ktv_deparse(.libPaths())),
    sprintf("dir <- %s; dir.create(dir)", ktv_deparse(dir)),
    "df <- data.frame(id = 1:3, score = c(0.5, 1, 2), name = c('a', 'b', 'c'))",
    "try_save <- function(label, expr) {",
    "  ok <- tryCatch({ force(expr); TRUE }, error = function(e) { cat('FAIL', label, ':', conditionMessage(e), '\\n'); FALSE })",
    "  if (ok) cat('OK', label, '\\n')",
    "}",
    "try_save('plot (HTML)', {",
    "  f <- file.path(dir, 'plot.html')",
    "  kits::kits_save_plot(plotly::plot_ly(df, x = ~id, y = ~score, type = 'scatter', mode = 'lines'), f)",
    "  stopifnot(file.size(f) > 1e6, !dir.exists(file.path(dir, 'plot_files')))",
    "})",
    "try_save('CSV', readr::write_excel_csv(df, file.path(dir, 'a.csv')))",
    "try_save('csv.gz', readr::write_csv(df, file.path(dir, 'a.csv.gz')))",
    "try_save('SAV', haven::write_sav(df, file.path(dir, 'a.sav')))",
    "try_save('zip', zip::zip(file.path(dir, 'a.zip'), file.path(dir, 'a.csv'), mode = 'cherry-pick'))"
  ), script)
  system2(ktv_rscript(), shQuote(script), stdout = log, stderr = log)
  lines <- readLines(log, warn = FALSE, encoding = "UTF-8")
  ok <- sub("^OK ", "", grep("^OK ", lines, value = TRUE))
  fail <- sub("^FAIL ", "", grep("^FAIL ", lines, value = TRUE))
  if (length(fail) == 0 && length(ok) == 5) {
    ktv_item("Saving files", "ok", paste(trimws(ok), collapse = ", "))
  } else {
    if (length(fail) == 0) fail <- ktv_log_errors(lines)
    hint <- if (any(grepl("pandoc", fail))) "\n    \u2192 run kitverse::kitverse_pandoc()" else ""
    ktv_item("Saving files", "fail", paste0(paste(trimws(fail), collapse = "\n    "), hint))
  }
}

#' Load packages in a separate R; returns the error messages (empty when all load)
#' @noRd
ktv_try_load <- function(pkgs) {
  script <- tempfile("kitverse-load-", fileext = ".R")
  log <- tempfile("kitverse-load-", fileext = ".log")
  on.exit(unlink(c(script, log)), add = TRUE)
  writeLines(c(
    sprintf(".libPaths(%s)", ktv_deparse(.libPaths())),
    sprintf("for (p in %s) tryCatch(suppressPackageStartupMessages(loadNamespace(p)),", ktv_deparse(pkgs)),
    "  error = function(e) cat(p, ': ', conditionMessage(e), '\\n', sep = ''))"
  ), script)
  system2(ktv_rscript(), shQuote(script), stdout = log, stderr = log)
  out <- readLines(log, warn = FALSE, encoding = "UTF-8")
  out[nzchar(trimws(out))]
}

#' Whether a URL can be reached
#' @noRd
ktv_online <- function(url) {
  h <- tryCatch(suppressWarnings(curlGetHeaders(url, timeout = 10)), error = function(e) NULL)
  !is.null(h) && attr(h, "status") < 400
}

#' Start an app in a separate R (no browser), wait for the page, then stop it
#' @noRd
ktv_check_app <- function(app, timeout = 120) {
  port <- ktv_free_port()
  pidfile <- tempfile("kitverse-pid-")
  log <- tempfile("kitverse-app-", fileext = ".log")
  script <- tempfile("kitverse-app-", fileext = ".R")
  on.exit(unlink(c(pidfile, script)), add = TRUE)
  writeLines(c(
    sprintf(".libPaths(%s)", ktv_deparse(.libPaths())),
    sprintf("writeLines(as.character(Sys.getpid()), %s)", ktv_deparse(pidfile)),
    sprintf("%s::%s(launch.browser = FALSE, host = '127.0.0.1', port = %dL)", app$pkg, app$run, port)
  ), script)
  t0 <- Sys.time()
  system2(ktv_rscript(), shQuote(script), stdout = log, stderr = log, wait = FALSE)
  url <- sprintf("http://127.0.0.1:%d/", port)
  ok <- FALSE
  while (as.numeric(difftime(Sys.time(), t0, units = "secs")) < timeout) {
    Sys.sleep(1)
    page <- tryCatch(suppressWarnings(readLines(url, warn = FALSE)), error = function(e) NULL)
    if (!is.null(page) && any(grepl("shiny", page, fixed = TRUE))) {
      ok <- TRUE
      break
    }
  }
  secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")))
  if (file.exists(pidfile)) tools::pskill(as.integer(readLines(pidfile, warn = FALSE)[1]))
  if (ok) {
    unlink(log)
    ktv_item(paste("Start", app$name), "ok", paste0("ready in ", secs, " s"))
  } else {
    tail_log <- ktv_log_errors(readLines(log, warn = FALSE, encoding = "UTF-8"))
    ktv_item(paste("Start", app$name), "fail",
             paste0("not ready within ", timeout, " s. Last messages:\n    ",
                    paste(tail_log, collapse = "\n    ")))
  }
}

#' A port nobody uses
#' @noRd
ktv_free_port <- function() {
  port <- tryCatch(httpuv::randomPort(), error = function(e) NULL)
  if (is.null(port)) port <- sample(49152:65000, 1)
  as.integer(port)
}

#' Print the check results
#' @noRd
ktv_print_check <- function(res) {
  mark <- c(ok = ktv_col("\u2714", "green"), fail = ktv_col("\u2716", "red"), note = ktv_col("!", "cyan"))
  cat("\n", ktv_rule(left = "Checking this computer",
                     right = paste("kitverse", ktv_installed_version("kitverse"))), "\n", sep = "")
  for (i in seq_len(nrow(res))) {
    cat(mark[[res$status[i]]], " ", res$item[i], ": ", res$detail[i], "\n", sep = "")
  }
  n_fail <- sum(res$status == "fail")
  if (n_fail == 0) {
    cat(ktv_col("\u2714", "green"), " All good. library(kitverse), then run_kitsui() or run_kitjoin().\n\n", sep = "")
  } else {
    cat(ktv_col("\u2716", "red"), " ", n_fail, " item", if (n_fail > 1) "s", " to fix (marked \u2716 above). ",
        "Please send a screenshot of this to the workshop assistants.\n\n", sep = "")
  }
}

#' One check line: are the KIT packages the versions of the current KIT release?
#' @noRd
ktv_check_release <- function(release, lib.loc = NULL) {
  if (is.null(release)) {
    return(ktv_item("KIT release", "note", "the list of the current release could not be read (no internet?)"))
  }
  have <- vapply(release$pkg, ktv_installed_version, character(1), lib.loc = lib.loc)
  shown <- paste0(release$pkg, " ", ifelse(is.na(have), "-", have))
  behind <- ktv_behind_release(release, lib.loc)
  tag <- if (nzchar(release$tag[1])) paste0(" (", release$tag[1], ")") else ""
  if (length(behind) == 0) {
    ktv_item("KIT release", "ok", paste0("current", tag, ": ", paste(shown, collapse = ", ")))
  } else {
    want <- paste0(release$pkg, " ", release$version)[release$pkg %in% behind]
    ktv_item("KIT release", "note", paste0(
      "older than the current release", tag, ": needs ", paste(want, collapse = ", "),
      "; run kitverse::kitverse_update(all = TRUE) or paste the install line again"
    ))
  }
}
