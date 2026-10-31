# 安裝缺少的、更新太舊的套件
#
# install.packages() 只裝沒有的套件，不會更新已經裝了但太舊的（例如 bslib 0.10 沒有
# Brite 主題，kitsUI 一打開就壞掉）。這裡照 kitverse_requirements() 找出沒裝或太舊的，
# 在另一個 R 裡安裝：Windows 上載入中的套件不能覆蓋，另一個 R 沒有載入任何套件。

#' 安裝缺少的、更新太舊的套件
#'
#' 找出 kitverse 需要、但沒有安裝或版本太舊的套件（[kitverse_requirements()]），
#' 從 [kitverse_repos()] 安裝。新裝的套件可能又需要別的套件，所以會重複到沒有缺的為止
#' （最多 `rounds` 次）。安裝在另一個 R 程序裡進行，現在這個 R 載入了什麼都沒關係。
#'
#' 剛裝好的 R 還沒有個人的套件資料夾，這裡會先建立（`R_LIBS_USER`）。
#'
#' @param all `TRUE` 時，套件庫有新版的也一起更新（不只是太舊的）。
#' @param rounds 最多重複幾次。
#' @param quiet `TRUE` 時不印安裝過程。
#' @return 裝了或更新了哪些套件（invisible）。
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
      # 套件庫有新版的（包括 kitverse 自己）
      old <- tryCatch(rownames(utils::old.packages(repos = repos)), error = function(e) NULL)
      todo <- union(todo, intersect(old, c(req$pkg, "kitverse")))
    }
    todo <- setdiff(todo, done)
    if (length(todo) == 0) break
    # 原文：正在安裝或更新  |  個套件： | 、
    kv_say("\u6b63\u5728\u5b89\u88dd\u6216\u66f4\u65b0 ", length(todo), " \u500b\u5957\u4ef6\uff1a", paste(todo, collapse = "\u3001"))
    # 原文：（第一次可能要幾分鐘，請不要關掉 R）
    kv_say("\uff08\u7b2c\u4e00\u6b21\u53ef\u80fd\u8981\u5e7e\u5206\u9418\uff0c\u8acb\u4e0d\u8981\u95dc\u6389 R\uff09")
    kv_install(todo, lib = lib, repos = repos, quiet = quiet)
    done <- c(done, todo)
  }
  req <- kitverse_requirements()
  if (all(req$ok)) {
    # 原文：✓ 套件都裝好了。下一步：kitverse::kitverse_check()
    kv_say("\u2713 \u5957\u4ef6\u90fd\u88dd\u597d\u4e86\u3002\u4e0b\u4e00\u6b65\uff1akitverse::kitverse_check()")
  } else {
    bad <- req[!req$ok, , drop = FALSE]
    # 原文：✗ 還有套件不能用： | ： | ；
    kv_say("\u2717 \u9084\u6709\u5957\u4ef6\u4e0d\u80fd\u7528\uff1a", paste0(bad$pkg, "\uff1a", bad$why, collapse = "\uff1b"))
    # 原文：  請確認電腦連上網路後再執行一次 kitverse::kitverse_update()。
    kv_say("  \u8acb\u78ba\u8a8d\u96fb\u8166\u9023\u4e0a\u7db2\u8def\u5f8c\u518d\u57f7\u884c\u4e00\u6b21 kitverse::kitverse_update()\u3002")
  }
  invisible(done)
}

#' 個人的套件資料夾：沒有就建立，放到搜尋路徑最前面
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

#' 在另一個 R 裡執行 install.packages()
#' @noRd
kv_install <- function(pkgs, lib, repos, quiet = FALSE) {
  script <- tempfile("kitverse-install-", fileext = ".R")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    # Posit Package Manager 看 user agent 決定給哪個 R 版本的 binary
    'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version[["platform"]], R.version[["arch"]], R.version[["os"]])))',
    sprintf("options(repos = %s)", kv_deparse(repos)),
    sprintf(".libPaths(c(%s, .libPaths()))", kv_deparse(lib)),
    sprintf("install.packages(%s, lib = %s, quiet = %s)",
            kv_deparse(pkgs), kv_deparse(lib), if (quiet) "TRUE" else "FALSE")
  ), script)
  status <- system2(kv_rscript(), shQuote(script))
  # 原文：（安裝程式結束時回報了錯誤，下面再檢查一次）
  if (!identical(status, 0L)) kv_say("\uff08\u5b89\u88dd\u7a0b\u5f0f\u7d50\u675f\u6642\u56de\u5831\u4e86\u932f\u8aa4\uff0c\u4e0b\u9762\u518d\u6aa2\u67e5\u4e00\u6b21\uff09")
  invisible(status)
}

#' 字串變成 R 程式碼（給另一個 R 執行的腳本用）
#' @noRd
kv_deparse <- function(x) paste(deparse(x, width.cutoff = 500L), collapse = " ")

#' 這個 R 的 Rscript
#' @noRd
kv_rscript <- function() {
  exe <- if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
  file.path(R.home("bin"), exe)
}

#' 印一行訊息（message()，可以用 suppressMessages() 關掉）
#' @noRd
kv_say <- function(...) message(paste0(...))
