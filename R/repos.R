# Where to install from: the KIT packages from r-universe, everything else from CRAN
#
# r-universe is a CRAN-like repository with pre-built Windows and macOS packages, and it does not
# go through the GitHub API (with 80 people in one room, remotes::install_github() runs into
# GitHub's limit of 60 requests per hour). CRAN has no Linux binaries, and building RTMB from
# source takes over ten minutes, so Ubuntu and Debian use Posit Package Manager's binaries.

#' The repositories packages are installed from
#'
#' The KIT packages come from r-universe (`https://jiewentsai.r-universe.dev`), everything else
#' from CRAN; on Ubuntu and Debian, CRAN is replaced by Posit Package Manager's pre-built packages.
#' `options(kitverse.repo = )` replaces r-universe (for example with an offline repository at
#' the workshop), and `options(kitverse.cran = )` replaces CRAN.
#'
#' @return A named vector of URLs, ready for `install.packages(repos = )`.
#' @examples
#' kitverse_repos()
#' @export
kitverse_repos <- function() {
  kit <- getOption("kitverse.repo", "https://jiewentsai.r-universe.dev")
  cran <- getOption("kitverse.cran", ktv_default_cran())
  c(kitverse = kit, CRAN = cran)
}

#' The default CRAN: Posit Package Manager binaries on Ubuntu/Debian, CRAN elsewhere
#' @noRd
ktv_default_cran <- function(os_release = "/etc/os-release") {
  cran <- "https://cloud.r-project.org"
  if (.Platform$OS.type != "unix" || Sys.info()[["sysname"]] != "Linux") return(cran)
  if (!file.exists(os_release)) return(cran)
  rel <- readLines(os_release, warn = FALSE)
  get <- function(key) {
    line <- grep(paste0("^", key, "="), rel, value = TRUE)
    if (length(line) == 0) "" else gsub("\"", "", sub("^[^=]*=", "", line[1]))
  }
  id <- get("ID")
  codename <- get("VERSION_CODENAME")
  if (!id %in% c("ubuntu", "debian") || !nzchar(codename)) return(cran)
  paste0("https://packagemanager.posit.co/cran/__linux__/", codename, "/latest")
}
