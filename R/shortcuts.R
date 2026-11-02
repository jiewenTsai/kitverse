# Desktop shortcuts: double-click to start an app (or to update), no RStudio needed
#
# On Windows, one shortcut per app on the desktop. Each runs this R's Rscript.exe with
# -e "kitsUI::run_kitsui()" (or run_kitjoin()): a console window opens, then the app opens in the
# browser. Closing that window stops the app. A third shortcut updates the packages
# (ktv_shortcut_update()). The shortcuts are made by PowerShell (WScript.Shell),
# which every Windows has; the desktop folder is the one Windows reports, so a desktop moved into
# OneDrive is found too.

#' Make desktop shortcuts for the two apps and for updating
#'
#' Puts one shortcut per app on the desktop, named after the tool in Chinese ("KIT ... tool" for
#' kitsUI and for kitJoin, the names in the app headers). Double-clicking
#' one starts that app with this R and opens it in the browser; no RStudio is needed. A black
#' console window stays open while the app runs: closing it stops the app.
#'
#' A third shortcut ("KIT tools update", in Chinese) installs the newest kitverse, then updates
#' every package to its newest version (`kitverse_update(all = TRUE)`) and remakes the shortcuts.
#' It waits for Enter at the end so the result can be read. Close the apps before updating.
#'
#' Run it again after installing a new version of R, so the shortcuts use the new R. The Windows
#' installer (`windows/install.ps1` in the kitverse repository) and `install.R` call it at the end.
#' For now only Windows is supported; elsewhere it does nothing and says how to start the apps.
#'
#' @param dir The folder for the shortcuts. `NULL` (default) is the desktop.
#' @return The paths of the shortcuts made (invisibly); an empty vector when none were made.
#' @examples
#' if (interactive()) kitverse_shortcuts()
#' @export
kitverse_shortcuts <- function(dir = NULL) {
  if (.Platform$OS.type != "windows") {
    ktv_say("Desktop shortcuts are only made on Windows. Start the apps in R with ",
            "kitsUI::run_kitsui() or kitJoin::run_kitjoin().")
    return(invisible(character(0)))
  }
  script <- tempfile(fileext = ".ps1")
  on.exit(unlink(script), add = TRUE)
  ktv_write_utf8_bom(ktv_shortcut_ps(ktv_shortcut_apps(), rscript = ktv_rscript(), dir = dir), script)
  out <- tryCatch(
    suppressWarnings(system2("powershell.exe",
                             c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", shQuote(script)),
                             stdout = TRUE, stderr = TRUE)),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )
  made <- out[file.exists(out)]
  if (!is.null(attr(out, "status")) || length(made) == 0) {
    ktv_say("\u2716 Could not make the desktop shortcuts: ", paste(out, collapse = " "))
    return(invisible(character(0)))
  }
  for (f in made) ktv_say("\u2714 ", f)
  invisible(made)
}

#' The shortcuts: file name (Chinese), the R code Rscript runs, the tooltip
#' @noRd
ktv_shortcut_apps <- function() {
  # 原文：雙擊開啟；關掉黑色視窗就會關閉 app
  app_tip <- "\u96d9\u64ca\u958b\u555f\uff1b\u95dc\u6389\u9ed1\u8272\u8996\u7a97\u5c31\u6703\u95dc\u9589 app"
  list(
    # 原文：KIT 量尺建構工具
    list(name = "KIT \u91cf\u5c3a\u5efa\u69cb\u5de5\u5177", expr = "kitsUI::run_kitsui()",
         tip = paste0("kitsUI: ", app_tip)),
    # 原文：KIT 資料處理工具
    list(name = "KIT \u8cc7\u6599\u8655\u7406\u5de5\u5177", expr = "kitJoin::run_kitjoin()",
         tip = paste0("kitJoin: ", app_tip)),
    # 原文：KIT 工具更新
    list(name = "KIT \u5de5\u5177\u66f4\u65b0", expr = "kitverse:::ktv_shortcut_update()",
         # 原文：雙擊更新 KIT 的套件（請先關掉所有 app 的黑色視窗）
         tip = "\u96d9\u64ca\u66f4\u65b0 KIT \u7684\u5957\u4ef6\uff08\u8acb\u5148\u95dc\u6389\u6240\u6709 app \u7684\u9ed1\u8272\u8996\u7a97\uff09")
  )
}

#' What the update shortcut runs
#'
#' kitverse is loaded in this R, and its files are replaced when it is updated: calling a kitverse
#' function that is not loaded yet would then fail ("R_decompress1"). So this keeps what it needs
#' first, installs kitverse in another R (ktv_install()), and runs the rest with the new kitverse in
#' a new R. Waits for Enter at the end, so the window stays open until the result is read.
#' @noRd
ktv_shortcut_update <- function() {
  say <- ktv_say
  rscript <- ktv_rscript()
  # 原文：== KIT 工具更新（請先關掉所有 KIT app 的黑色視窗）
  say("== KIT \u5de5\u5177\u66f4\u65b0\uff08\u8acb\u5148\u95dc\u6389\u6240\u6709 KIT app \u7684\u9ed1\u8272\u8996\u7a97\uff09")
  # 原文：== 1/2 更新 kitverse
  say("== 1/2 \u66f4\u65b0 kitverse")
  ktv_install("kitverse", lib = ktv_user_library(), repos = kitverse_repos())
  # 原文：== 2/2 更新其他套件、重建桌面捷徑
  say("== 2/2 \u66f4\u65b0\u5176\u4ed6\u5957\u4ef6\u3001\u91cd\u5efa\u684c\u9762\u6377\u5f91")
  status <- system2(rscript, c("-e", shQuote(
    "kitverse::kitverse_update(all = TRUE); kitverse::kitverse_shortcuts()")))
  say("")
  if (identical(status, 0L)) {
    # 原文：更新完成。
    say("\u66f4\u65b0\u5b8c\u6210\u3002")
  } else {
    # 原文：更新沒有完成：請把這個視窗截圖給助教。
    say("\u66f4\u65b0\u6c92\u6709\u5b8c\u6210\uff1a\u8acb\u628a\u9019\u500b\u8996\u7a97\u622a\u5716\u7d66\u52a9\u6559\u3002")
  }
  # 原文：按 Enter 關閉這個視窗。
  say("\u6309 Enter \u95dc\u9589\u9019\u500b\u8996\u7a97\u3002")
  invisible(readLines(file("stdin"), n = 1))
}

#' The PowerShell script that makes the shortcuts and prints each path
#' @param apps [ktv_shortcut_apps()].
#' @param rscript Path of Rscript.exe.
#' @param dir Folder for the shortcuts; `NULL` is the desktop.
#' @noRd
ktv_shortcut_ps <- function(apps, rscript, dir = NULL) {
  q <- function(x) paste0("'", gsub("'", "''", x, fixed = TRUE), "'")   # PowerShell '...'
  win <- function(x) gsub("/", "\\", x, fixed = TRUE)
  rscript <- win(normalizePath(rscript, winslash = "/", mustWork = FALSE))
  icon <- file.path(dirname(rscript), "Rgui.exe")
  folder <- if (is.null(dir)) "[Environment]::GetFolderPath('Desktop')" else q(win(dir))
  one <- function(a) {
    c(
      sprintf("$l = $sh.CreateShortcut((Join-Path $dir %s))", q(paste0(a$name, ".lnk"))),
      sprintf("$l.TargetPath = %s", q(rscript)),
      sprintf("$l.Arguments = %s", q(sprintf('-e "%s"', a$expr))),
      "$l.WorkingDirectory = $env:USERPROFILE",
      sprintf("if (Test-Path %s) { $l.IconLocation = %s }", q(win(icon)), q(paste0(win(icon), ",0"))),
      sprintf("$l.Description = %s", q(a$tip)),
      "$l.Save()",
      "$l.FullName"
    )
  }
  c("$ErrorActionPreference = 'Stop'",
    sprintf("$dir = %s", folder),
    "if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }",
    "$sh = New-Object -ComObject WScript.Shell",
    unlist(lapply(apps, one)))
}

#' Write lines as UTF-8 with a BOM (Windows PowerShell 5.1 reads a script without one as ANSI)
#' @noRd
ktv_write_utf8_bom <- function(lines, file) {
  con <- file(file, "wb")
  on.exit(close(con))
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  writeBin(charToRaw(enc2utf8(paste0(paste(lines, collapse = "\r\n"), "\r\n"))), con)
}
