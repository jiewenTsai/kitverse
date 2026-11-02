# library(kitverse): attach the core packages like tidyverse, and list versions and conflicts
#
# Loading the kitverse namespace loads no other package (NAMESPACE has no imports), so
# kitverse_check() and kitverse_update() still work when a package is broken.
# Only library(kitverse) attaches the core packages; when one cannot be loaded it says how
# to fix it instead of making library() fail.
#
# What it prints (the tidyverse format):
#
#   ── Attaching core kitverse packages ─────────────────────── kitverse 0.4.0 ──
#   ✔ kits      0.25.2     ✔ kitJoin   0.7.0
#   ✔ kitsUI    0.6.0      ✔ kitDesign 0.5.0
#   ── Conflicts ─────────────────────────────────────── kitverse_conflicts() ──
#   ✖ kitJoin::kit_app() masks kitsUI::kit_app()
#   ℹ Start an app: run_kitsui() or run_kitjoin(). Check this computer: kitverse_check()

ktv_core <- function() c("kits", "kitsUI", "kitJoin", "kitDesign")

.onAttach <- function(libname, pkgname) {
  # Only the ones not attached yet (a second library() prints nothing)
  todo <- ktv_core()[!paste0("package:", ktv_core()) %in% search()]
  if (length(todo) == 0) return(invisible())
  packageStartupMessage(ktv_attach_message(ktv_attach(todo)))
}

#' Attach the core packages: check the versions first, library() only those that are fine
#'
#' Returns a data frame: `pkg`, `version`, `ok`, `why` (the reason when not ok), and `fix`
#' (`"update"`: a package is missing or too old; `"restart"`: this R session has an older
#' version loaded than the one installed, which only a restart of R fixes).
#' @noRd
ktv_attach <- function(pkgs = ktv_core()) {
  req <- kitverse_requirements()
  bad <- req[!req$ok, , drop = FALSE]
  out <- lapply(pkgs, function(pkg) {
    # The package itself, or a package it needs, is missing or too old
    need <- kitverse_requirements(roots = pkg)
    broken <- rbind(bad[bad$pkg == pkg, , drop = FALSE], need[!need$ok, , drop = FALSE])
    broken <- broken[!duplicated(broken$pkg), , drop = FALSE]
    # Loaded in this session at another version than the one installed (installed while loaded)
    stale <- ktv_stale_loaded(c(pkg, need$pkg))
    fix <- ""
    why <- if (nrow(broken) > 0) {
      fix <- "update"
      paste0(broken$pkg, " ", broken$why, collapse = "; ")
    } else if (nrow(stale) > 0) {
      fix <- "restart"
      paste0(stale$pkg, " ", stale$loaded, " is loaded in this R session, but ", stale$installed,
             " is installed", collapse = "; ")
    } else {
      tryCatch({
        suppressPackageStartupMessages(
          do.call("library", list(pkg, character.only = TRUE, warn.conflicts = FALSE))
        )
        ""
      }, error = function(e) {
        fix <<- if (grepl("is already loaded", conditionMessage(e))) "restart" else "update"
        paste0("failed to load: ", conditionMessage(e))
      })
    }
    data.frame(pkg = pkg, version = ktv_installed_version(pkg), ok = !nzchar(why), why = why,
               fix = fix, stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

#' Packages loaded in this session at a version other than the installed one
#'
#' Happens when a package is updated while R has it loaded: R keeps using the old version,
#' and reading the rest of it from the new files gives errors such as
#' "internal error ... in R_decompress1". Only a restart of R fixes it.
#' @noRd
ktv_stale_loaded <- function(pkgs) {
  pkgs <- unique(pkgs[vapply(pkgs, isNamespaceLoaded, logical(1))])
  loaded <- vapply(pkgs, function(p) as.character(getNamespaceVersion(p)), character(1))
  installed <- vapply(pkgs, ktv_installed_version, character(1))
  keep <- !is.na(installed) & loaded != installed
  data.frame(pkg = pkgs[keep], loaded = unname(loaded[keep]), installed = unname(installed[keep]),
             stringsAsFactors = FALSE)
}

#' The message library(kitverse) prints
#' @noRd
ktv_attach_message <- function(res, conflicts = kitverse_conflicts(only = res$pkg[res$ok])) {
  lines <- ktv_rule(left = "Attaching core kitverse packages",
                    right = paste("kitverse", ktv_installed_version("kitverse")))

  # Two columns: ✔ package version (pad the plain text first, then color it)
  mark <- ifelse(res$ok, ktv_col("\u2714", "green"), ktv_col("\u2716", "red"))
  ver <- ifelse(is.na(res$version), "", res$version)
  cells <- paste0(mark, " ", ktv_col(formatC(res$pkg, width = -max(nchar(res$pkg))), "blue"), " ",
                  formatC(ver, width = -max(nchar(ver))))
  if (length(cells) %% 2 == 1) cells <- c(cells, "")
  half <- length(cells) / 2
  lines <- c(lines, trimws(paste0(cells[seq_len(half)], "     ", cells[half + seq_len(half)]), "right"))

  if (any(!res$ok)) {
    for (i in which(!res$ok)) lines <- c(lines, paste0("  ", res$pkg[i], ": ", res$why[i]))
    if (any(res$fix == "restart")) {
      lines <- c(lines, paste("\u2192 Restart R (in RStudio: Session > Restart R), then",
                              "library(kitverse) again."))
    }
    if (any(res$fix == "update")) {
      lines <- c(lines, "\u2192 Run kitverse::kitverse_update(), then restart R.")
    }
  }

  if (nrow(conflicts) > 0) {
    lines <- c(lines, ktv_rule(left = "Conflicts", right = "kitverse_conflicts()"),
               ktv_format_conflicts(conflicts))
  }
  lines <- c(lines, paste(ktv_col("\u2139", "cyan"), "Start an app: run_kitsui() or run_kitjoin().",
                          "Check this computer: kitverse_check()"))
  paste(lines, collapse = "\n")
}

#' Color text with cli (plain text where the console has no colors, for example Rgui)
#' @noRd
ktv_col <- function(x, color) {
  fun <- switch(color, green = cli::col_green, red = cli::col_red, blue = cli::col_blue,
                cyan = cli::col_cyan, grey = cli::col_grey)
  as.character(fun(x))
}

#' ── left text ──────── right text ── (as wide as the console, at most 80)
#' @noRd
ktv_rule <- function(left, right, width = getOption("width", 80)) {
  width <- min(width, 80)
  used <- nchar(left, type = "width") + nchar(right, type = "width") + 8
  paste0(ktv_col("\u2500\u2500", "grey"), " ", cli::style_bold(left), " ",
         ktv_col(strrep("\u2500", max(width - used, 3)), "grey"), " ", right, " ",
         ktv_col("\u2500\u2500", "grey"))
}

#' Conflicts between the core packages and other attached packages
#'
#' Lists functions in the core packages (kits, kitsUI, kitJoin, kitDesign) that have the same
#' name as a function in another attached package: which one wins and which ones are masked.
#' Writing the prefix (`kits::`) always gets that package's version. `library(kitverse)` prints
#' this, like `tidyverse_conflicts()`.
#'
#' @param only Only these core packages (default: all of them that are attached).
#' @return A data frame that prints one line per conflict: `name`, `winner` (the package in use),
#'   `losers` (the masked packages).
#' @examples
#' kitverse_conflicts()
#' @export
kitverse_conflicts <- function(only = ktv_core()) {
  envs <- search()
  core <- paste0("package:", only)
  core <- core[core %in% envs]
  empty <- data.frame(name = character(0), winner = character(0), losers = character(0),
                      stringsAsFactors = FALSE)
  if (length(core) == 0) return(structure(empty, class = c("kitverse_conflicts", "data.frame")))
  # Positions on the search path, not names: the same name can appear twice
  objs <- lapply(seq_along(envs), function(i) ls(pos = i, all.names = FALSE))
  rows <- list()
  for (i in match(core, envs)) {
    for (name in objs[[i]]) {
      where <- which(vapply(objs, function(o) name %in% o, logical(1)))
      if (length(where) < 2 || where[1] != i) next  # no conflict, or masked by another package (listed there)
      fn <- vapply(where, function(j) is.function(get(name, pos = j)), logical(1))
      if (!fn[1]) next
      losers <- unique(sub("^package:", "", envs[where[-1][fn[-1]]]))
      if (length(losers) == 0) next
      rows[[length(rows) + 1]] <- data.frame(name = name, winner = sub("^package:", "", envs[i]),
                                             losers = paste(losers, collapse = ", "),
                                             stringsAsFactors = FALSE)
    }
  }
  res <- if (length(rows)) do.call(rbind, rows) else empty
  structure(res, class = c("kitverse_conflicts", "data.frame"))
}

#' @export
print.kitverse_conflicts <- function(x, ...) {
  if (nrow(x) == 0) cat("No conflicts.\n") else cat(ktv_format_conflicts(x), sep = "\n")
  invisible(x)
}

#' ✖ kits::x() masks stats::x()
#' @noRd
ktv_format_conflicts <- function(conflicts) {
  vapply(seq_len(nrow(conflicts)), function(i) {
    losers <- strsplit(conflicts$losers[i], ", ", fixed = TRUE)[[1]]
    paste0(ktv_col("\u2716", "red"), " ", ktv_col(paste0(conflicts$winner[i], "::", conflicts$name[i], "()"), "blue"),
           " masks ", paste0(losers, "::", conflicts$name[i], "()", collapse = ", "))
  }, character(1))
}
