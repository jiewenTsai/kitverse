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
#    starts kitsUI and kitJoin);
# 4. on Windows, puts a shortcut for each app on the desktop (kitverse_shortcuts()).
#
# On Windows, windows/install.ps1 also installs R first, then runs this file.
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

  message("== 1/4 Installing kitverse (the first time takes about 3-10 minutes; please keep R open)")
  # Only when the repository has a newer kitverse (a newer one installed from GitHub stays)
  have <- tryCatch(as.character(utils::packageVersion("kitverse")), error = function(e) NA_character_)
  ap <- tryCatch(utils::available.packages(repos = repos), error = function(e) NULL)
  latest <- if (!is.null(ap) && "kitverse" %in% rownames(ap)) ap["kitverse", "Version"] else NA_character_
  if (is.na(have) || is.na(latest) || package_version(latest) > package_version(have)) {
    install.packages("kitverse", lib = lib, repos = repos)
  } else {
    message("   kitverse ", have, " is already installed (the repository has ", latest, ")")
  }
  if (!requireNamespace("kitverse", quietly = TRUE)) {
    stop("kitverse was not installed. Check the internet connection and paste the line again; ",
         "if it still fails, send a screenshot to the workshop assistants.", call. = FALSE)
  }
  message("== 2/4 Updating packages that are too old")
  kitverse::kitverse_update()
  message("== 3/4 Checking this computer")
  kitverse::kitverse_check()
  if (.Platform$OS.type == "windows" && "kitverse_shortcuts" %in% getNamespaceExports("kitverse")) {
    message("== 4/4 Desktop shortcuts")
    kitverse::kitverse_shortcuts()
  }
})
