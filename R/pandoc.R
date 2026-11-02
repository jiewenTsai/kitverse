# Pandoc: saving a plot as one html file needs it
#
# kitsUI saves plotly plots with htmlwidgets::saveWidget(selfcontained = TRUE), which calls
# pandoc through rmarkdown. RStudio and Quarto come with pandoc, but R started outside RStudio (the
# desktop shortcuts, Rscript) does not know where; a computer with only R has none, so the plot
# downloads do not work. kitverse_update() first looks where RStudio and Quarto keep their pandoc
# and uses that one; only when there is none does it download pandoc into kitverse's own data
# folder. Either way it sets RSTUDIO_PANDOC in the user's ~/.Renviron, so every new R session finds
# it (library(kitverse), run_kitsui(), the desktop shortcuts alike).
#
# Pandoc comes from its GitHub release files at a fixed version: plain downloads, not the GitHub
# API, so 80 people in one room do not hit the API limit.

ktv_pandoc_version <- function() "3.7.0.2"

#' Install pandoc if R cannot find one
#'
#' Saving a plot as one html file (the plot downloads in kitsUI) needs pandoc. RStudio and Quarto
#' come with it, but R started outside RStudio does not know where; a computer with only R has none.
#' When R cannot find pandoc, this first looks where RStudio and Quarto are usually installed and
#' uses their pandoc; only when there is none does it download pandoc (about 20–40 MB) into
#' kitverse's data folder. Either way it adds `RSTUDIO_PANDOC` to the user's `~/.Renviron`, so every
#' new R session finds it. [kitverse_update()] calls this.
#'
#' `options(kitverse.pandoc_url = )` replaces the download folder (for example an offline copy
#' at the workshop); it must hold the same file names as the pandoc GitHub release.
#'
#' @param force `TRUE` to install even when R already finds pandoc.
#' @return The folder that holds pandoc (invisibly), or `NULL` when nothing could be installed.
#' @examples
#' if (interactive()) kitverse_pandoc()
#' @export
kitverse_pandoc <- function(force = FALSE) {
  if (!force && ktv_pandoc_found()) return(invisible(ktv_pandoc_dir()))
  dir <- ktv_pandoc_home()
  bin <- ktv_pandoc_bin(dir)
  # RStudio's or Quarto's pandoc, when R does not know about it (no download needed)
  if (is.null(bin) && !force) bin <- ktv_pandoc_existing()
  if (is.null(bin)) {
    asset <- ktv_pandoc_asset()
    if (is.null(asset)) {
      ktv_say("\u2716 No pandoc download for this computer (", R.version$platform, "). ",
              "Install pandoc from https://pandoc.org to save plots.")
      return(invisible(NULL))
    }
    base <- getOption("kitverse.pandoc_url", paste0(
      "https://github.com/jgm/pandoc/releases/download/", ktv_pandoc_version()))
    ktv_say("Installing pandoc ", ktv_pandoc_version(), " (needed to save plots; about 20-40 MB)")
    archive <- file.path(tempdir(), asset)
    ok <- tryCatch({
      old <- options(timeout = max(600, getOption("timeout")))
      on.exit(options(old), add = TRUE)
      utils::download.file(paste0(base, "/", asset), archive, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      ktv_say("\u2716 Could not download pandoc: ", conditionMessage(e))
      FALSE
    })
    if (!ok) return(invisible(NULL))
    unlink(dir, recursive = TRUE)
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    if (grepl("\\.zip$", asset)) utils::unzip(archive, exdir = dir) else utils::untar(archive, exdir = dir)
    unlink(archive)
    bin <- ktv_pandoc_bin(dir)
    if (is.null(bin)) {
      ktv_say("\u2716 The pandoc download did not contain pandoc.")
      return(invisible(NULL))
    }
    Sys.chmod(bin, "755")
  }
  folder <- normalizePath(dirname(bin), winslash = "/")
  Sys.setenv(RSTUDIO_PANDOC = folder)
  ktv_renviron_set("RSTUDIO_PANDOC", folder)
  if (ktv_pandoc_found()) {
    ktv_say("\u2714 pandoc is ready (", folder, ")")
  } else {
    ktv_say("\u2716 pandoc was installed in ", folder, " but R cannot run it.")
  }
  invisible(folder)
}

#' Whether rmarkdown (which htmlwidgets uses) finds a pandoc
#' @noRd
ktv_pandoc_found <- function() {
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    # rmarkdown caches what it found; look again (RSTUDIO_PANDOC may have just been set)
    tryCatch(rmarkdown::find_pandoc(cache = FALSE), error = function(e) NULL)
    return(isTRUE(rmarkdown::pandoc_available()))
  }
  nzchar(Sys.which("pandoc"))
}

#' The folder of the pandoc rmarkdown uses ("" when none)
#' @noRd
ktv_pandoc_dir <- function() {
  if (!ktv_pandoc_found()) return("")
  if (requireNamespace("rmarkdown", quietly = TRUE)) return(dirname(rmarkdown::pandoc_exec()))
  dirname(Sys.which("pandoc"))
}

#' Pandoc that RStudio or Quarto installed (NULL when there is none)
#' @param dirs Folders to look in, first match wins.
#' @noRd
ktv_pandoc_existing <- function(dirs = ktv_pandoc_known_dirs()) {
  exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  hits <- file.path(dirs, exe)
  hits <- hits[file.exists(hits)]
  if (length(hits) == 0) NULL else hits[1]
}

#' Where RStudio and Quarto keep pandoc (newer layouts first)
#' @noRd
ktv_pandoc_known_dirs <- function(sysname = Sys.info()[["sysname"]]) {
  quarto <- Sys.which("quarto")
  on_path <- if (nzchar(quarto)) file.path(dirname(quarto), "tools") else character(0)
  arch <- c("aarch64", "x86_64")
  switch(sysname,
    Windows = {
      roots <- unique(c(Sys.getenv("ProgramFiles"), file.path(Sys.getenv("LOCALAPPDATA"), "Programs")))
      roots <- roots[nzchar(roots)]
      c(file.path(roots, "RStudio", "resources", "app", "bin", "quarto", "bin", "tools"),
        file.path(roots, "RStudio", "bin", "quarto", "bin", "tools"),
        file.path(roots, "RStudio", "bin", "pandoc"),
        file.path(roots, "Quarto", "bin", "tools"),
        on_path)
    },
    Darwin = {
      rs <- "/Applications/RStudio.app/Contents"
      c(file.path(rs, "Resources", "app", "quarto", "bin", "tools", arch),
        file.path(rs, "Resources", "app", "quarto", "bin", "tools"),
        file.path(rs, "MacOS", "quarto", "bin", "tools"),
        file.path("/Applications/quarto/bin/tools", arch),
        "/Applications/quarto/bin/tools",
        on_path)
    },
    c("/usr/lib/rstudio/resources/app/bin/quarto/bin/tools", "/usr/lib/rstudio/bin/quarto/bin/tools",
      "/usr/lib/rstudio/bin/pandoc", "/opt/quarto/bin/tools", on_path)
  )
}

#' Where kitverse keeps its pandoc
#' @noRd
ktv_pandoc_home <- function() {
  file.path(tools::R_user_dir("kitverse", "data"), "pandoc")
}

#' The pandoc program inside a folder (NULL when there is none)
#' @noRd
ktv_pandoc_bin <- function(dir) {
  if (!dir.exists(dir)) return(NULL)
  exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  hits <- list.files(dir, pattern = paste0("^", exe, "$"), recursive = TRUE, full.names = TRUE)
  if (length(hits) == 0) NULL else hits[1]
}

#' The pandoc release file for this computer (NULL when there is none)
#' @noRd
ktv_pandoc_asset <- function(sysname = Sys.info()[["sysname"]], machine = Sys.info()[["machine"]]) {
  arm <- grepl("arm64|aarch64", machine)
  suffix <- switch(sysname,
    Windows = if (!arm) "windows-x86_64.zip",
    Darwin = if (arm) "arm64-macOS.zip" else "x86_64-macOS.zip",
    Linux = if (arm) "linux-arm64.tar.gz" else "linux-amd64.tar.gz",
    NULL)
  if (is.null(suffix)) return(NULL)
  paste0("pandoc-", ktv_pandoc_version(), "-", suffix)
}

#' Set NAME=value in the user's ~/.Renviron (replacing an earlier line for NAME)
#' @noRd
ktv_renviron_set <- function(name, value, file = path.expand("~/.Renviron")) {
  lines <- if (file.exists(file)) readLines(file, warn = FALSE) else character(0)
  lines <- lines[!grepl(paste0("^\\s*", name, "\\s*="), lines)]
  lines <- c(lines, paste0(name, "=\"", value, "\""))
  tryCatch({
    writeLines(lines, file)
    TRUE
  }, error = function(e) {
    ktv_say("! Could not write ", file, ": ", conditionMessage(e),
            ". Add this line to it yourself: ", name, "=\"", value, "\"")
    FALSE
  })
}
