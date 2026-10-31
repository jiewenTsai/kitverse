# Which packages are needed, their minimum versions, and whether they are installed
#
# Starting from kitverse's own DESCRIPTION, read the DESCRIPTION of each installed package,
# level by level (Depends, Imports, LinkingTo), and keep the minimum version each package is
# required at (the highest one). Only DESCRIPTION files are read, no package is loaded: a
# package that is too old fails as soon as it loads, and on Windows a loaded package cannot be
# overwritten.

# Packages that come with R: nothing to install or check
kv_base_pkgs <- function() {
  c("R", rownames(utils::installed.packages(priority = "base")))
}

#' Parse DESCRIPTION dependency fields: package names and minimum versions (NA when none)
#' @noRd
kv_parse_deps <- function(fields) {
  fields <- fields[!is.na(fields)]
  if (length(fields) == 0) {
    return(data.frame(pkg = character(0), min = character(0), stringsAsFactors = FALSE))
  }
  items <- trimws(unlist(strsplit(paste(fields, collapse = ","), ",")))
  items <- gsub("\\s+", " ", items[nzchar(items)])
  pkg <- sub("^([A-Za-z0-9.]+).*$", "\\1", items)
  min <- ifelse(grepl(">=", items), sub("^.*>=\\s*([0-9.-]+).*$", "\\1", items), NA_character_)
  data.frame(pkg = pkg, min = min, stringsAsFactors = FALSE)
}

#' One package's DESCRIPTION dependencies (NULL when not installed)
#' @noRd
kv_desc_deps <- function(pkg, lib.loc = NULL) {
  path <- system.file("DESCRIPTION", package = pkg, lib.loc = lib.loc)
  if (!nzchar(path)) return(NULL)
  d <- read.dcf(path, fields = c("Depends", "Imports", "LinkingTo"))[1, ]
  kv_parse_deps(d)
}

#' The installed version (NA when not installed)
#' @noRd
kv_installed_version <- function(pkg, lib.loc = NULL) {
  path <- system.file("DESCRIPTION", package = pkg, lib.loc = lib.loc)
  if (!nzchar(path)) return(NA_character_)
  unname(read.dcf(path, fields = "Version")[1, 1])
}

#' The higher of two minimum versions (NA means no requirement)
#' @noRd
kv_max_version <- function(a, b) {
  if (is.na(a)) return(b)
  if (is.na(b)) return(a)
  if (utils::compareVersion(a, b) >= 0) a else b
}

#' All packages kitverse needs
#'
#' Starting from `roots` (kitverse itself by default), reads the DESCRIPTION of the installed
#' packages and finds every package needed directly or indirectly, the minimum version required,
#' and the installed version. A package that is not installed has no DESCRIPTION to read, so the
#' packages below it show up only after it is installed ([kitverse_update()] repeats until nothing
#' is missing).
#'
#' @param roots The packages to start from.
#' @param lib.loc Package libraries (default `.libPaths()`).
#' @return A data frame: `pkg`, `min` (minimum version, NA when none), `have` (installed version,
#'   NA when not installed), `ok` (installed and new enough), `why` (the reason when not ok).
#' @examples
#' req <- kitverse_requirements()
#' req[!req$ok, ]
#' @export
kitverse_requirements <- function(roots = "kitverse", lib.loc = NULL) {
  base <- kv_base_pkgs()
  need <- list()
  queue <- roots
  seen <- character(0)
  while (length(queue) > 0) {
    pkg <- queue[1]
    queue <- queue[-1]
    if (pkg %in% seen) next
    seen <- c(seen, pkg)
    deps <- kv_desc_deps(pkg, lib.loc)
    if (is.null(deps)) next
    deps <- deps[!deps$pkg %in% base, , drop = FALSE]
    for (i in seq_len(nrow(deps))) {
      p <- deps$pkg[i]
      old <- if (is.null(need[[p]])) NA_character_ else need[[p]]
      need[[p]] <- kv_max_version(old, deps$min[i])
    }
    queue <- c(queue, setdiff(deps$pkg, seen))
  }
  pkgs <- sort(names(need))
  min <- vapply(pkgs, function(p) need[[p]], character(1), USE.NAMES = FALSE)
  have <- vapply(pkgs, kv_installed_version, character(1), lib.loc = lib.loc, USE.NAMES = FALSE)
  too_old <- !is.na(have) & !is.na(min) &
    mapply(function(h, m) utils::compareVersion(h, m) < 0, have, ifelse(is.na(min), "0", min),
           USE.NAMES = FALSE)
  why <- ifelse(is.na(have), "not installed",
                ifelse(too_old, paste0("too old (", have, "; needs ", min, " or later)"), ""))
  data.frame(pkg = pkgs, min = min, have = have, ok = !is.na(have) & !too_old, why = why,
             stringsAsFactors = FALSE)
}
