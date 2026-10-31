# 開 app：先確認套件都好，再交給 kitsUI／kitJoin 自己的啟動函式

#' 開啟 kitsUI（量尺建構工具）
#'
#' 先確認套件都裝了、版本夠新（不夠時說要執行 [kitverse_update()]），再呼叫
#' `kitsUI::run_kitsui()`：瀏覽器會自動打開 app。關掉 app：在 R 按 Esc（或 Ctrl+C）。
#'
#' @param ... 傳給 `kitsUI::run_kitsui()`（例如 `port = 8001`、`launch.browser = FALSE`）。
#' @return `NULL`（invisible）。
#' @examples
#' if (interactive()) kitsui()
#' @export
kitsui <- function(...) {
  kv_launch("kitsUI", "run_kitsui", ...)
}

#' 開啟 kitJoin（資料串接工具）
#'
#' 先確認套件都裝了、版本夠新（不夠時說要執行 [kitverse_update()]），再呼叫
#' `kitJoin::run_kitjoin()`：瀏覽器會自動打開 app。關掉 app：在 R 按 Esc（或 Ctrl+C）。
#'
#' @param ... 傳給 `kitJoin::run_kitjoin()`（例如 `port = 8002`、`launch.browser = FALSE`）。
#' @return `NULL`（invisible）。
#' @examples
#' if (interactive()) kitjoin()
#' @export
kitjoin <- function(...) {
  kv_launch("kitJoin", "run_kitjoin", ...)
}

#' 確認套件都好，再呼叫 app 自己的啟動函式
#' @noRd
kv_launch <- function(pkg, run, ...) {
  req <- kitverse_requirements(roots = pkg)
  bad <- req[!req$ok, , drop = FALSE]
  if (!nzchar(system.file(package = pkg))) bad <- rbind(bad, data.frame(
    # 原文：沒有安裝
    pkg = pkg, min = NA_character_, have = NA_character_, ok = FALSE, why = "\u6c92\u6709\u5b89\u88dd",
    stringsAsFactors = FALSE))
  if (nrow(bad) > 0) {
    # 原文： 還不能開，這些套件要先處理：
    stop(pkg, " \u9084\u4e0d\u80fd\u958b\uff0c\u9019\u4e9b\u5957\u4ef6\u8981\u5148\u8655\u7406\uff1a",
         # 原文：： | ；
         paste0(bad$pkg, "\uff1a", bad$why, collapse = "\uff1b"),
         # 原文：\n請執行 kitverse::kitverse_update()，再試一次。
         "\n\u8acb\u57f7\u884c kitverse::kitverse_update()\uff0c\u518d\u8a66\u4e00\u6b21\u3002", call. = FALSE)
  }
  # 原文：正在開啟  | … 瀏覽器會自動打開。用完在這裡按 Esc（或 Ctrl+C）關掉。
  kv_say("\u6b63\u5728\u958b\u555f ", pkg, "\u2026 \u700f\u89bd\u5668\u6703\u81ea\u52d5\u6253\u958b\u3002\u7528\u5b8c\u5728\u9019\u88e1\u6309 Esc\uff08\u6216 Ctrl+C\uff09\u95dc\u6389\u3002")
  fun <- getExportedValue(pkg, run)
  fun(...)
  invisible(NULL)
}
