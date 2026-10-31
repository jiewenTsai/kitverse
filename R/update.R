# Install missing packages and update packages that are too old
#
# install.packages() installs only missing packages; it does not update one that is installed
# but too old (for example bslib 0.10 has no Brite theme, and kitsUI breaks as soon as it
# opens). This finds what is missing or too old with kitverse_requirements() and installs it
# in a separate R: on Windows a loaded package cannot be overwritten, and the other R has
# nothing loaded.

#' Install missing packages and update packages that are too old
#'
#' Finds the packages kitverse needs that are not installed or older than required
#' ([kitverse_requirements()]) and installs them from [kitverse_repos()]. A newly installed
#' package may need further packages, so this repeats until nothing is missing (at most
#' `rounds` times). The installation runs in a separate R process, so it does not matter what
#' the current R session has loaded.
#'
#' A freshly installed R has no personal package library yet; this creates it first
#' (`R_LIBS_USER`).
#'
#' @param all `TRUE` to also update packages that have a newer version in the repositories
#'   (not only those that are too old).
#' @param rounds At most how many rounds.
#' @param quiet `TRUE` to hide the installation output.
#' @return The packages installed or updated (invisibly).
#' @examples
#' if (interactive()) kitverse_update()
#' @export
kitverse_update <- function(all = FALSE, rounds = 4, quiet = FALSE) {
  lib <- kv_user_library()
  repos <- kitverse_repos()
  done <- character(0)
  for (i in seq_len(rounds)) {
    req <- kitverse_requirements()
    todo <- req$pkg[!req$ok]
    if (all && i == 1) {
      # Packages with a newer version in the repositories (kitverse itself too)
      old <- tryCatch(rownames(utils::old.packages(repos = repos)), error = function(e) NULL)
      todo <- union(todo, intersect(old, c(req$pkg, "kitverse")))
    }
    todo <- setdiff(todo, done)
    if (length(todo) == 0) break
    kv_say("Installing or updating ", length(todo), " package", if (length(todo) > 1) "s",
           ": ", paste(todo, collapse = ", "))
    kv_say("(the first time can take a few minutes; please keep R open)")
    kv_install(todo, lib = lib, repos = repos, quiet = quiet)
    done <- c(done, todo)
  }
  req <- kitverse_requirements()
  if (all(req$ok)) {
    kv_say("\u2714 All packages are installed.")
    # Saving plots as html needs pandoc; a computer with only R has none
    kitverse_pandoc()
    kv_say("Next: kitverse::kitverse_check()")
  } else {
    bad <- req[!req$ok, , drop = FALSE]
    kv_say("\u2716 Some packages still cannot be used: ", paste(bad$pkg, bad$why, collapse = "; "))
    kv_say("  Check the internet connection and run kitverse::kitverse_update() again.")
  }
  invisible(done)
}

#' The personal package library: create it if needed and put it first on the library path
#' @noRd
kv_user_library <- function() {
  lib <- Sys.getenv("R_LIBS_USER")
  if (!nzchar(lib)) return(.libPaths()[1])
  lib <- path.expand(strsplit(lib, .Platform$path.sep, fixed = TRUE)[[1]][1])
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(lib) || file.access(lib, 2) != 0) return(.libPaths()[1])
  .libPaths(c(lib, .libPaths()))
  lib
}

#' Run install.packages() in a separate R
#' @noRd
kv_install <- function(pkgs, lib, repos, quiet = FALSE) {
  script <- tempfile("kitverse-install-", fileext = ".R")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    # Posit Package Manager picks the binary for this R version from the user agent
    'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version[["platform"]], R.version[["arch"]], R.version[["os"]])))',
    sprintf("options(repos = %s)", kv_deparse(repos)),
    sprintf(".libPaths(c(%s, .libPaths()))", kv_deparse(lib)),
    sprintf("install.packages(%s, lib = %s, quiet = %s)",
            kv_deparse(pkgs), kv_deparse(lib), if (quiet) "TRUE" else "FALSE")
  ), script)
  status <- system2(kv_rscript(), shQuote(script))
  if (!identical(status, 0L)) kv_say("(the installer reported an error; checking again below)")
  invisible(status)
}

#' A value as R code (for the script the other R runs)
#' @noRd
kv_deparse <- function(x) paste(deparse(x, width.cutoff = 500L), collapse = " ")

#' This R's Rscript
#' @noRd
kv_rscript <- function() {
  exe <- if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
  file.path(R.home("bin"), exe)
}

#' Print one line (message(), so suppressMessages() can hide it)
#' @noRd
kv_say <- function(...) message(paste0(...))
