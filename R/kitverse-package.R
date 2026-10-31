#' kitverse: install the KIT research tools in one step
#'
#' Installing kitverse installs kits, kitsUI, kitJoin, kitDesign and every package they need.
#' Like tidyverse, `library(kitverse)` attaches these core packages and lists their versions;
#' their functions are then used directly, for example `run_kitsui()` and `run_kitjoin()`.
#'
#' kitverse itself only adds the helpers:
#'
#' - [kitverse_check()]: check this computer (R, packages, and really starting both apps).
#' - [kitverse_update()]: install missing packages and update those that are too old.
#' - [kitverse_conflicts()]: functions in the core packages that mask other functions.
#' - [kitverse_requirements()]: which packages and versions are needed.
#' - [kitverse_repos()]: where packages are installed from.
#'
#' Install (Windows and macOS need no Rtools or Xcode):
#'
#' ```r
#' install.packages("kitverse", repos = c("https://jiewentsai.r-universe.dev",
#'                                        "https://cloud.r-project.org"))
#' kitverse::kitverse_update()
#' kitverse::kitverse_check()
#' ```
#'
#' @keywords internal
"_PACKAGE"
