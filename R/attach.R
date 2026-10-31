# library(kitverse)：像 tidyverse 一樣載入核心套件，列出版本與名稱衝突
#
# 載入 kitverse 的 namespace 時不載入任何其他套件（NAMESPACE 沒有 import），
# 所以套件壞掉時 kitverse_check() 與 kitverse_update() 還是能用。
# library(kitverse) 時才載入核心套件；載不起來就說怎麼修，不讓 library() 失敗。
#
# 印出來的樣子（tidyverse 的格式）：
#
#   ── 載入 kitverse 的核心套件 ─────────────────────── kitverse 0.1.0 ──
#   ✔ kits      0.25.2     ✔ kitJoin   0.6.0
#   ✔ kitsUI    0.5.0      ✔ kitDesign 0.4.0
#   ── 名稱衝突 ─────────────────────────────────── kitverse_conflicts() ──
#   ✖ kitJoin::x() 蓋過 kitsUI::x()
#   ℹ 開 app：kitsui()、kitjoin()　檢查電腦：kitverse_check()

kv_core <- function() c("kits", "kitsUI", "kitJoin", "kitDesign")

.onAttach <- function(libname, pkgname) {
  # 不在搜尋路徑上的才載入（再 library() 一次不用重印）
  todo <- kv_core()[!paste0("package:", kv_core()) %in% search()]
  if (length(todo) == 0) return(invisible())
  packageStartupMessage(kv_attach_message(kv_attach(todo)))
}

#' 載入核心套件：先看套件版本，夠新的才 library()
#'
#' 回傳 data.frame：`pkg`、`version`、`ok`、`why`（不 ok 的原因）。
#' @noRd
kv_attach <- function(pkgs = kv_core()) {
  req <- kitverse_requirements()
  bad <- req[!req$ok, , drop = FALSE]
  out <- lapply(pkgs, function(pkg) {
    why <- ""
    # 這個套件自己，或它需要的套件，沒裝或太舊
    need <- kitverse_requirements(roots = pkg)
    broken <- rbind(bad[bad$pkg == pkg, , drop = FALSE], need[!need$ok, , drop = FALSE])
    broken <- broken[!duplicated(broken$pkg), , drop = FALSE]
    if (nrow(broken) > 0) {
      # 原文：： | ；
      why <- paste0(broken$pkg, "\uff1a", broken$why, collapse = "\uff1b")
    } else {
      why <- tryCatch({
        suppressPackageStartupMessages(
          do.call("library", list(pkg, character.only = TRUE, warn.conflicts = FALSE))
        )
        ""
      # 原文：載入失敗：
      }, error = function(e) paste0("\u8f09\u5165\u5931\u6557\uff1a", conditionMessage(e)))
    }
    data.frame(pkg = pkg, version = kv_installed_version(pkg), ok = !nzchar(why), why = why,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

#' library(kitverse) 時印的訊息
#' @noRd
kv_attach_message <- function(res, conflicts = kitverse_conflicts(only = res$pkg[res$ok])) {
  # 原文：載入 kitverse 的核心套件
  lines <- kv_rule(left = "\u8f09\u5165 kitverse \u7684\u6838\u5fc3\u5957\u4ef6",
                   right = paste("kitverse", kv_installed_version("kitverse")))

  # 兩欄：✔ 套件 版本
  # 原文：✔ | ✖
  mark <- ifelse(res$ok, "\u2714", "\u2716")
  ver <- ifelse(is.na(res$version), "", res$version)
  cells <- paste0(mark, " ", formatC(res$pkg, width = -max(nchar(res$pkg))), " ",
                  formatC(ver, width = -max(nchar(ver))))
  if (length(cells) %% 2 == 1) cells <- c(cells, "")
  half <- length(cells) / 2
  lines <- c(lines, trimws(paste0(cells[seq_len(half)], "     ", cells[half + seq_len(half)]), "right"))

  if (any(!res$ok)) {
    # 原文：：
    for (i in which(!res$ok)) lines <- c(lines, paste0("  ", res$pkg[i], "\uff1a", res$why[i]))
    # 原文：→ 請執行 kitverse::kitverse_update()，再重新開 R。
    lines <- c(lines, "\u2192 \u8acb\u57f7\u884c kitverse::kitverse_update()\uff0c\u518d\u91cd\u65b0\u958b R\u3002")
  }

  if (nrow(conflicts) > 0) {
    # 原文：名稱衝突
    lines <- c(lines, kv_rule(left = "\u540d\u7a31\u885d\u7a81", right = "kitverse_conflicts()"),
               kv_format_conflicts(conflicts))
  }
  # 原文：ℹ 開 app：kitsui()、kitjoin()　檢查電腦：kitverse_check()
  lines <- c(lines, "\u2139 \u958b app\uff1akitsui()\u3001kitjoin()\u3000\u6aa2\u67e5\u96fb\u8166\uff1akitverse_check()")
  paste(lines, collapse = "\n")
}

#' ── 左邊的字 ──────── 右邊的字 ── （寬度跟著 console；中文算兩格）
#' @noRd
kv_rule <- function(left, right, width = getOption("width", 80)) {
  width <- min(width, 80)
  used <- nchar(left, type = "width") + nchar(right, type = "width") + 8
  # 原文：──  | ─ |  ──
  paste0("\u2500\u2500 ", left, " ", strrep("\u2500", max(width - used, 3)), " ", right, " \u2500\u2500")
}

#' 核心套件的名稱衝突
#'
#' 列出核心套件（kits、kitsUI、kitJoin、kitDesign）裡，和搜尋路徑上其他套件同名的函式：
#' 哪一個蓋過了哪一個。打 `kits::` 這樣的前綴，就一定用到那個套件的版本。
#' `library(kitverse)` 時會印出來（像 `tidyverse_conflicts()`）。
#'
#' @param only 只看這些核心套件（預設是全部有載入的）。
#' @return data.frame（印出來是一行一個衝突）：`name`、`winner`（現在用的套件）、`losers`（被蓋過的套件）。
#' @examples
#' kitverse_conflicts()
#' @export
kitverse_conflicts <- function(only = kv_core()) {
  envs <- search()
  core <- paste0("package:", only)
  core <- core[core %in% envs]
  empty <- data.frame(name = character(0), winner = character(0), losers = character(0),
                      stringsAsFactors = FALSE)
  if (length(core) == 0) return(structure(empty, class = c("kitverse_conflicts", "data.frame")))
  # 用搜尋路徑上的位置，不用名稱：同一個名稱可能出現兩次
  objs <- lapply(seq_along(envs), function(i) ls(pos = i, all.names = FALSE))
  rows <- list()
  for (i in match(core, envs)) {
    for (name in objs[[i]]) {
      where <- which(vapply(objs, function(o) name %in% o, logical(1)))
      if (length(where) < 2 || where[1] != i) next  # 沒有衝突，或被別的套件蓋過（別的套件那邊會列）
      fn <- vapply(where, function(j) is.function(get(name, pos = j)), logical(1))
      if (!fn[1]) next
      losers <- unique(sub("^package:", "", envs[where[-1][fn[-1]]]))
      if (length(losers) == 0) next
      rows[[length(rows) + 1]] <- data.frame(name = name, winner = sub("^package:", "", envs[i]),
                                             losers = paste(losers, collapse = ", "),
                                             stringsAsFactors = FALSE)
    }
  }
  res <- if (length(rows)) do.call(rbind, rows) else empty
  structure(res, class = c("kitverse_conflicts", "data.frame"))
}

#' @export
print.kitverse_conflicts <- function(x, ...) {
  # 原文：沒有名稱衝突。\n
  if (nrow(x) == 0) cat("\u6c92\u6709\u540d\u7a31\u885d\u7a81\u3002\n") else cat(kv_format_conflicts(x), sep = "\n")
  invisible(x)
}

#' ✖ kits::x() 蓋過 stats::x()
#' @noRd
kv_format_conflicts <- function(conflicts) {
  vapply(seq_len(nrow(conflicts)), function(i) {
    losers <- strsplit(conflicts$losers[i], ", ", fixed = TRUE)[[1]]
    # 原文：✖  | () 蓋過 
    paste0("\u2716 ", conflicts$winner[i], "::", conflicts$name[i], "() \u84cb\u904e ",
           # 原文：、
           paste0(losers, "::", conflicts$name[i], "()", collapse = "\u3001"))
  }, character(1))
}
