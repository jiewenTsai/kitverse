# library(kitverse)：像 tidyverse 一樣載入主要的套件，列出版本
#
# 載入 kitverse 的 namespace 時不載入任何其他套件（NAMESPACE 沒有 import），
# 所以套件壞掉時 kitverse_check() 與 kitverse_update() 還是能用。
# library(kitverse) 時才載入主要套件；載不起來就說怎麼修，不讓 library() 失敗。

kv_core <- function() c("kits", "kitsUI", "kitJoin", "kitDesign")

.onAttach <- function(libname, pkgname) {
  req <- kitverse_requirements()
  bad <- req[!req$ok, , drop = FALSE]
  if (nrow(bad) > 0) {
    packageStartupMessage(
      # 原文：✗ 有套件沒裝或太舊： | ： | ；
      "\u2717 \u6709\u5957\u4ef6\u6c92\u88dd\u6216\u592a\u820a\uff1a", paste0(bad$pkg, "\uff1a", bad$why, collapse = "\uff1b"),
      # 原文：\n  請執行 kitverse::kitverse_update()，再重新開 R。
      "\n  \u8acb\u57f7\u884c kitverse::kitverse_update()\uff0c\u518d\u91cd\u65b0\u958b R\u3002"
    )
    return(invisible())
  }
  loaded <- character(0)
  for (pkg in kv_core()) {
    ok <- tryCatch({
      suppressPackageStartupMessages(
        do.call("library", list(pkg, character.only = TRUE, warn.conflicts = FALSE))
      )
      TRUE
    }, error = function(e) {
      # 原文：✗  |  載入失敗：
      packageStartupMessage("\u2717 ", pkg, " \u8f09\u5165\u5931\u6557\uff1a", conditionMessage(e))
      FALSE
    })
    if (ok) loaded <- c(loaded, paste(pkg, kv_installed_version(pkg)))
  }
  packageStartupMessage(
    # 原文：── kitverse  |  ── 
    "\u2500\u2500 kitverse ", kv_installed_version("kitverse"), " \u2500\u2500 ",
    # 原文：、
    paste(loaded, collapse = "\u3001"),
    # 原文：\n開 app：kitsui()、kitjoin()　檢查電腦：kitverse_check()
    "\n\u958b app\uff1akitsui()\u3001kitjoin()\u3000\u6aa2\u67e5\u96fb\u8166\uff1akitverse_check()"
  )
}
