# Install kitverse with one line: open R and paste
#
#   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
#
# It does three things:
# 1. creates the personal package library (a freshly installed R has none, and
#    install.packages() then asks questions or fails);
# 2. installs kitverse and every package it needs from r-universe (pre-built on Windows and
#    macOS, so no Rtools or Xcode; on Ubuntu/Debian, pre-built from Posit Package Manager);
# 3. updates packages that are installed but too old, installs pandoc when R has none (saving
#    plots needs it), then checks this computer (it saves one file of each kind and really
#    starts kitsUI and kitJoin).
#
# Offline repository at the workshop: Sys.setenv(KITVERSE_REPO = "file:///...",
# KITVERSE_CRAN = "file:///...") first, then source() this file.
local({
  kit <- Sys.getenv("KITVERSE_REPO", "https://jiewentsai.r-universe.dev")
  cran <- Sys.getenv("KITVERSE_CRAN", "https://cloud.r-project.org")
  if (Sys.info()[["sysname"]] == "Linux" && file.exists("/etc/os-release") &&
      cran == "https://cloud.r-project.org") {
    rel <- readLines("/etc/os-release", warn = FALSE)
    id <- gsub("\"", "", sub("^ID=", "", grep("^ID=", rel, value = TRUE)[1]))
    codename <- sub("^VERSION_CODENAME=", "", grep("^VERSION_CODENAME=", rel, value = TRUE)[1])
    if (id %in% c("ubuntu", "debian") && !is.na(codename) && nzchar(codename)) {
      cran <- paste0("https://packagemanager.posit.co/cran/__linux__/", codename, "/latest")
    }
  }
  repos <- c(kitverse = kit, CRAN = cran)
  options(
    repos = repos, kitverse.repo = kit, kitverse.cran = cran,
    # Posit Package Manager picks the binary for this R version from the user agent
    HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
      paste(getRversion(), R.version[["platform"]], R.version[["arch"]], R.version[["os"]]))
  )

  lib <- path.expand(strsplit(Sys.getenv("R_LIBS_USER"), .Platform$path.sep, fixed = TRUE)[[1]][1])
  if (!is.na(lib) && nzchar(lib)) {
    dir.create(lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(lib, .libPaths()))
  }
  lib <- .libPaths()[1]

  message("== 1/3 Installing kitverse (the first time takes about 3-10 minutes; please keep R open)")
  install.packages("kitverse", lib = lib, repos = repos)
  if (!requireNamespace("kitverse", quietly = TRUE)) {
    stop("kitverse was not installed. Check the internet connection and paste the line again; ",
         "if it still fails, send a screenshot to the workshop assistants.", call. = FALSE)
  }
  message("== 2/3 Updating packages that are too old")
  kitverse::kitverse_update()
  message("== 3/3 Checking this computer")
  kitverse::kitverse_check()
})
