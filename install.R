# Install kitverse with one line: open R and paste
#
#   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
#
# It does three things:
# 1. creates the personal package library (a freshly installed R has none, and
#    install.packages() then asks questions or fails);
# 2. installs kitverse and every package it needs from r-universe (pre-built on Windows and
#    macOS, so no Rtools or Xcode; on Ubuntu/Debian, pre-built from Posit Package Manager);
#    when r-universe is behind the KIT release on GitHub (bundle/kit-bundle.dcf), the KIT
#    packages come from that release instead (they are plain R, so no Rtools either);
# 3. updates packages that are installed but too old, installs pandoc when R has none (saving
#    plots needs it), then checks this computer (it saves one file of each kind and really
#    starts kitsUI and kitJoin);
# 4. on Windows, puts a shortcut for each app on the desktop (kitverse_shortcuts()).
#
# On Windows, windows/install.ps1 also installs R first, then runs this file.
#
# Offline repository at the workshop: Sys.setenv(KITVERSE_REPO = "file:///...",
# KITVERSE_CRAN = "file:///...") first, then source() this file. KITVERSE_BUNDLE points to
# another copy of the KIT release list (for example on the same USB stick).
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
    kitverse.bundle = Sys.getenv("KITVERSE_BUNDLE",
      "https://raw.githubusercontent.com/jiewenTsai/kitverse/main/bundle/kit-bundle.dcf"),
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
  have <- tryCatch(as.character(utils::packageVersion("kitverse")), error = function(e) NA_character_)
  ap <- tryCatch(utils::available.packages(repos = repos), error = function(e) NULL)
  latest <- if (!is.null(ap) && "kitverse" %in% rownames(ap)) ap["kitverse", "Version"] else NA_character_
  # The KIT release on GitHub: used when r-universe has not caught up with it yet
  bundle <- Sys.getenv("KITVERSE_BUNDLE",
                       "https://raw.githubusercontent.com/jiewenTsai/kitverse/main/bundle/kit-bundle.dcf")
  rel <- tryCatch({
    con <- if (grepl("^https?://", bundle)) url(bundle) else file(bundle)
    on.exit(close(con), add = TRUE)
    read.dcf(con, fields = c("Package", "Version", "URL", "Needs", "Tag"))
  }, error = function(e) NULL, warning = function(w) NULL)
  rel_kv <- if (!is.null(rel) && "kitverse" %in% rel[, "Package"]) {
    rel[rel[, "Package"] == "kitverse", "Version"]
  } else NA_character_
  newer <- function(a, b) !is.na(a) && (is.na(b) || package_version(a) > package_version(b))
  if (newer(rel_kv, latest) && newer(rel_kv, have)) {
    message("   r-universe has kitverse ", latest, "; installing the KIT release ",
            rel[1, "Tag"], " from GitHub")
    # The packages they need (from CRAN), then the five KIT packages in order
    items <- trimws(unlist(strsplit(paste(rel[, "Needs"][!is.na(rel[, "Needs"])], collapse = ","), ",")))
    items <- items[nzchar(items)]
    pkgs <- unique(sub("^([A-Za-z0-9.]+).*$", "\\1", items))
    pkgs <- setdiff(pkgs, c("R", rownames(utils::installed.packages(priority = "base")), rel[, "Package"]))
    mins <- vapply(pkgs, function(p) {
      hit <- grep(paste0("^", p, " *\\(>="), items, value = TRUE)
      if (length(hit) == 0) NA_character_ else sub("^.*>= *([0-9.-]+).*$", "\\1", hit[1])
    }, character(1))
    todo <- pkgs[vapply(seq_along(pkgs), function(i) {
      v <- tryCatch(as.character(utils::packageVersion(pkgs[i])), error = function(e) NA_character_)
      is.na(v) || (!is.na(mins[i]) && package_version(v) < package_version(mins[i]))
    }, logical(1))]
    if (length(todo) > 0) install.packages(todo, lib = lib, repos = repos)
    for (u in rel[, "URL"]) install.packages(u, lib = lib, repos = NULL, type = "source")
  } else if (newer(latest, have)) {
    # Only when the repository has a newer kitverse (a newer one installed from GitHub stays)
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
