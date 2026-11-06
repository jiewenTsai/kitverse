# The KIT release on GitHub: a fallback for when r-universe lags behind
#
# r-universe rebuilds the KIT packages after each push, but it can lag by hours, and once (2026-11-04)
# its own deploy step failed and it stopped updating for two days. A KIT release is one GitHub release
# of the kitverse repository with the five KIT packages as source tarballs, listed in
# bundle/kit-bundle.dcf (package, version, download address, and the other packages it needs). All
# five are plain R (no compiled code), so a source tarball installs on Windows and macOS without
# Rtools or Xcode; the packages they need still come as pre-built packages from CRAN.
#
# Release downloads come from github.com, not the GitHub API, so 80 people in one room do not hit
# GitHub's limit of 60 API requests per hour.

# The KIT packages, in the order they are installed (each needs only the ones before it)
KTV_KIT_PKGS <- c("kitDesign", "kits", "kitJoin", "kitsUI", "kitverse")

#' Where the list of the current KIT release is
#' @noRd
ktv_bundle_url <- function() {
  getOption("kitverse.bundle",
            "https://raw.githubusercontent.com/jiewenTsai/kitverse/main/bundle/kit-bundle.dcf")
}

#' The current KIT release on GitHub
#'
#' Reads `bundle/kit-bundle.dcf` of the kitverse repository: one entry per KIT package with its
#' version and the address of its source tarball in the GitHub release. `options(kitverse.bundle = )`
#' points somewhere else (for example a copy on a USB stick at the workshop).
#'
#' @param url Address (or file path) of the list.
#' @return A data frame: `pkg`, `version`, `url`, `mirror` (a second address), `needs` (the other packages it needs, as in
#'   DESCRIPTION), `tag`. `NULL` when the list cannot be read.
#' @examples
#' \donttest{kitverse_release()}
#' @export
kitverse_release <- function(url = ktv_bundle_url()) {
  old <- options(timeout = max(30, getOption("timeout")))
  on.exit(options(old), add = TRUE)
  d <- tryCatch({
    con <- if (grepl("^https?://", url)) url(url) else file(url)
    on.exit(close(con), add = TRUE)
    read.dcf(con, fields = c("Package", "Version", "URL", "Mirror", "Needs", "Tag"))
  }, error = function(e) NULL, warning = function(w) NULL)
  if (is.null(d) || nrow(d) == 0 || anyNA(d[, c("Package", "Version", "URL")])) return(NULL)
  data.frame(pkg = d[, "Package"], version = d[, "Version"], url = d[, "URL"],
             mirror = ifelse(is.na(d[, "Mirror"]), "", d[, "Mirror"]),
             needs = ifelse(is.na(d[, "Needs"]), "", d[, "Needs"]),
             tag = ifelse(is.na(d[, "Tag"]), "", d[, "Tag"]), stringsAsFactors = FALSE)
}

#' The KIT packages whose repository version is older than the release (or missing there)
#'
#' @param release kitverse_release(); repos the repositories (r-universe first)
#' @return The package names, in install order
#' @noRd
ktv_bundle_needed <- function(release, repos, pkgs = release$pkg) {
  if (is.null(release)) return(character(0))
  ap <- tryCatch(suppressWarnings(utils::available.packages(repos = repos)), error = function(e) NULL)
  lag <- vapply(pkgs, function(p) {
    rel <- release$version[release$pkg == p]
    if (length(rel) == 0) return(FALSE)
    have <- if (!is.null(ap) && p %in% rownames(ap)) ap[p, "Version"] else NA_character_
    is.na(have) || utils::compareVersion(have, rel) < 0
  }, logical(1))
  intersect(release$pkg, pkgs[lag])
}

#' Install KIT packages from the GitHub release (in a separate R)
#'
#' First the packages they need from CRAN (missing or older than required), then the tarballs in
#' order. All of `pkgs` are reinstalled; the packages they need only when missing or too old.
#' @noRd
ktv_bundle_install <- function(pkgs, release, lib, cran, quiet = FALSE) {
  rel <- release[match(intersect(release$pkg, pkgs), release$pkg), , drop = FALSE]
  if (nrow(rel) == 0) return(invisible(0L))
  needs <- ktv_parse_deps(rel$needs)
  needs <- needs[!needs$pkg %in% c(ktv_base_pkgs(), KTV_KIT_PKGS), , drop = FALSE]
  script <- tempfile("kitverse-release-", fileext = ".R")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version[["platform"]], R.version[["arch"]], R.version[["os"]])))',
    sprintf("options(repos = %s)", ktv_deparse(c(CRAN = unname(cran)))),
    sprintf("lib <- %s", ktv_deparse(lib)),
    ".libPaths(c(lib, .libPaths()))",
    sprintf("needs <- %s", ktv_deparse(needs)),
    "too_old <- function(p, min) {",
    "  path <- system.file('DESCRIPTION', package = p)",
    "  if (!nzchar(path)) return(TRUE)",
    "  !is.na(min) && utils::compareVersion(read.dcf(path, 'Version')[1, 1], min) < 0",
    "}",
    "todo <- unique(needs$pkg[mapply(too_old, needs$pkg, needs$min)])",
    sprintf("if (length(todo) > 0) install.packages(todo, lib = lib, quiet = %s)", quiet),
    # Each file from its first address that works (see install.R: some Windows computers cannot
    # open github.com from R, and some networks block the certificate revocation check)
    "fetch <- function(urls, dest) {",
    "  urls <- urls[!is.na(urls) & nzchar(urls)]",
    "  tries <- list(list(), list(revoke = TRUE))",
    "  if (.Platform$OS.type == 'windows') tries <- c(tries, list(list(method = 'wininet')))",
    "  for (u in urls) for (t in tries) {",
    "    if (isTRUE(t$revoke)) Sys.setenv(R_LIBCURL_SSL_REVOKE_BEST_EFFORT = 'TRUE')",
    "    ok <- tryCatch({",
    "      suppressWarnings(utils::download.file(u, dest, mode = 'wb', quiet = TRUE,",
    "        method = if (is.null(t$method)) 'libcurl' else t$method))",
    "      file.exists(dest) && file.size(dest) > 0",
    "    }, error = function(e) FALSE)",
    "    if (ok) return(TRUE)",
    "  }",
    "  FALSE",
    "}",
    sprintf("urls <- %s", ktv_deparse(rel$url)),
    sprintf("mirrors <- %s", ktv_deparse(rel$mirror)),
    "files <- character(0)",
    "for (i in seq_along(urls)) {",
    "  dest <- file.path(tempdir(), basename(urls[i]))",
    "  if (fetch(c(urls[i], mirrors[i]), dest)) files <- c(files, dest)",
    "  else message('could not download ', basename(urls[i]))",
    "}",
    sprintf("if (length(files) > 0) install.packages(files, lib = lib, repos = NULL, type = 'source', quiet = %s)",
            quiet)
  ), script)
  status <- system2(ktv_rscript(), shQuote(script))
  if (!identical(status, 0L)) ktv_say("(the installer reported an error; checking again below)")
  invisible(status)
}
