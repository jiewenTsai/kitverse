# 檢查這台電腦能不能用 KIT 的工具
#
# 一項一行，✓ 是好的、✗ 要處理、! 可以用但要知道。最後一項真的把每個 app 開起來
# （在另一個 R 裡，不開瀏覽器），確認網頁回得來，再關掉。

#' 檢查這台電腦能不能用 KIT 的工具
#'
#' 一項一行：R 的版本、個人套件資料夾能不能寫、每個套件有沒有裝、版本夠不夠新、
#' 套件載不載得起來、暫存資料夾、字型要用的網路，最後把 kitsUI 與 kitJoin 真的開起來
#' （在另一個 R 裡、不開瀏覽器）確認網頁回得來。工作坊前請學員執行一次，把結果截圖給助教。
#'
#' @param apps `TRUE` 時把 app 真的開起來試（每個約 5–30 秒）。
#' @param timeout 每個 app 最多等幾秒。
#' @return data.frame（invisible）：`item`、`status`（`"ok"`、`"fail"`、`"note"`）、`detail`。
#' @examples
#' if (interactive()) kitverse_check()
#' @export
kitverse_check <- function(apps = TRUE, timeout = 120) {
  res <- kv_check_items()
  # 原文：套件版本 | 套件載入
  if (apps && all(res$status[res$item %in% c("\u5957\u4ef6\u7248\u672c", "\u5957\u4ef6\u8f09\u5165")] == "ok")) {
    for (app in kv_apps()) {
      res <- rbind(res, kv_check_app(app, timeout = timeout))
    }
  } else if (apps) {
    # 原文：開啟 app | 套件有問題，先執行 kitverse::kitverse_update()
    res <- rbind(res, kv_item("\u958b\u555f app", "fail", "\u5957\u4ef6\u6709\u554f\u984c\uff0c\u5148\u57f7\u884c kitverse::kitverse_update()"))
  }
  kv_print_check(res)
  invisible(res)
}

#' 兩個 app：名稱、套件、啟動函式
#' @noRd
kv_apps <- function() {
  list(
    list(name = "kitsUI", pkg = "kitsUI", run = "run_kitsui"),
    list(name = "kitJoin", pkg = "kitJoin", run = "run_kitjoin")
  )
}

#' 一列檢查結果
#' @noRd
kv_item <- function(item, status, detail) {
  data.frame(item = item, status = status, detail = detail, stringsAsFactors = FALSE)
}

#' 不用開 app 的檢查
#' @noRd
kv_check_items <- function(req = kitverse_requirements()) {
  out <- list()
  # R 的版本：套件要 4.1 以上；Windows 上 4.2 起才全面用 UTF-8（中文檔名、中文欄名）
  rv <- getRversion()
  out[[length(out) + 1]] <- if (rv < "4.1.0") {
    # 原文：：太舊，請裝最新版的 R（https://cran.r-project.org）
    kv_item("R", "fail", paste0(rv, "\uff1a\u592a\u820a\uff0c\u8acb\u88dd\u6700\u65b0\u7248\u7684 R\uff08https://cran.r-project.org\uff09"))
  } else if (.Platform$OS.type == "windows" && rv < "4.2.0") {
    # 原文：：可以用，但中文檔名可能有問題；建議裝最新版的 R
    kv_item("R", "note", paste0(rv, "\uff1a\u53ef\u4ee5\u7528\uff0c\u4f46\u4e2d\u6587\u6a94\u540d\u53ef\u80fd\u6709\u554f\u984c\uff1b\u5efa\u8b70\u88dd\u6700\u65b0\u7248\u7684 R"))
  } else {
    kv_item("R", "ok", as.character(rv))
  }

  lib <- .libPaths()[1]
  out[[length(out) + 1]] <- if (file.access(lib, 2) == 0) {
    # 原文：套件資料夾
    kv_item("\u5957\u4ef6\u8cc7\u6599\u593e", "ok", lib)
  } else {
    # 原文：套件資料夾 | ：不能寫入；執行 kitverse::kitverse_update() 會建立個人的套件資料夾
    kv_item("\u5957\u4ef6\u8cc7\u6599\u593e", "fail", paste0(lib, "\uff1a\u4e0d\u80fd\u5beb\u5165\uff1b\u57f7\u884c kitverse::kitverse_update() \u6703\u5efa\u7acb\u500b\u4eba\u7684\u5957\u4ef6\u8cc7\u6599\u593e"))
  }

  bad <- req[!req$ok, , drop = FALSE]
  out[[length(out) + 1]] <- if (nrow(bad) == 0) {
    # 原文：套件版本 |  個套件都裝了，版本也夠新
    kv_item("\u5957\u4ef6\u7248\u672c", "ok", paste0(nrow(req), " \u500b\u5957\u4ef6\u90fd\u88dd\u4e86\uff0c\u7248\u672c\u4e5f\u5920\u65b0"))
  } else {
    # 原文：套件版本 | ： | ；
    kv_item("\u5957\u4ef6\u7248\u672c", "fail", paste0(paste0(bad$pkg, "\uff1a", bad$why, collapse = "\uff1b"),
                                   # 原文：\n    → 執行 kitverse::kitverse_update()
                                   "\n    \u2192 \u57f7\u884c kitverse::kitverse_update()"))
  }

  # 主要套件載不載得起來（在另一個 R 裡：這裡載入失敗會留下壞掉的狀態）
  main <- c("kits", "kitDesign", "kitsUI", "kitJoin")
  out[[length(out) + 1]] <- if (nrow(bad) > 0) {
    # 原文：套件載入 | 先處理上面的套件版本
    kv_item("\u5957\u4ef6\u8f09\u5165", "fail", "\u5148\u8655\u7406\u4e0a\u9762\u7684\u5957\u4ef6\u7248\u672c")
  } else {
    err <- kv_try_load(main)
    if (length(err) == 0) {
      # 原文：套件載入 | 、
      kv_item("\u5957\u4ef6\u8f09\u5165", "ok", paste0(main, " ", vapply(main, kv_installed_version, ""), collapse = "\u3001"))
    } else {
      # 原文：套件載入
      kv_item("\u5957\u4ef6\u8f09\u5165", "fail", paste(err, collapse = "\n    "))
    }
  }

  # Linux：套件編好的 .so 要的系統函式庫（例如 fs 要 libuv.so.1）。少了的話套件載得起來，
  # 要等 app 畫頁面、用到那個套件時才出錯
  if (Sys.info()[["sysname"]] == "Linux") {
    miss <- kv_missing_syslibs(req$pkg)
    out[[length(out) + 1]] <- if (length(miss) == 0) {
      # 原文：系統函式庫 | 套件需要的都有
      kv_item("\u7cfb\u7d71\u51fd\u5f0f\u5eab", "ok", "\u5957\u4ef6\u9700\u8981\u7684\u90fd\u6709")
    } else {
      apt <- kv_apt_name(miss)
      # 原文：系統函式庫
      kv_item("\u7cfb\u7d71\u51fd\u5f0f\u5eab", "fail", paste0(
        # 原文：缺少  | 、 | （ | 、
        "\u7f3a\u5c11 ", paste(names(miss), collapse = "\u3001"), "\uff08", paste(unique(unlist(miss)), collapse = "\u3001"),
        # 原文： 要用）\n    → 在終端機執行：sudo apt install 
        " \u8981\u7528\uff09\n    \u2192 \u5728\u7d42\u7aef\u6a5f\u57f7\u884c\uff1asudo apt install ", paste(apt, collapse = " ")))
    }
  }

  tmp <- tempdir()
  probe <- tempfile("kitverse-", tmpdir = tmp)
  ok_tmp <- tryCatch({ writeLines("ok", probe); unlink(probe); TRUE }, error = function(e) FALSE,
                     warning = function(w) FALSE)
  out[[length(out) + 1]] <- if (!ok_tmp) {
    # 原文：暫存資料夾 | ：不能寫入（上傳的檔案與下載的結果都放在這裡）
    kv_item("\u66ab\u5b58\u8cc7\u6599\u593e", "fail", paste0(tmp, "\uff1a\u4e0d\u80fd\u5beb\u5165\uff08\u4e0a\u50b3\u7684\u6a94\u6848\u8207\u4e0b\u8f09\u7684\u7d50\u679c\u90fd\u653e\u5728\u9019\u88e1\uff09"))
  } else if (.Platform$OS.type == "windows" && grepl("[^\\x01-\\x7F]", tmp, perl = TRUE)) {
    # 原文：暫存資料夾 | ：路徑裡有中文；如果上傳或下載出錯，請告訴助教
    kv_item("\u66ab\u5b58\u8cc7\u6599\u593e", "note", paste0(tmp, "\uff1a\u8def\u5f91\u88e1\u6709\u4e2d\u6587\uff1b\u5982\u679c\u4e0a\u50b3\u6216\u4e0b\u8f09\u51fa\u932f\uff0c\u8acb\u544a\u8a34\u52a9\u6559"))
  } else {
    # 原文：暫存資料夾
    kv_item("\u66ab\u5b58\u8cc7\u6599\u593e", "ok", tmp)
  }

  out[[length(out) + 1]] <- if (kv_online("https://fonts.googleapis.com/css2?family=Chiron+GoRound+TC")) {
    # 原文：網路（字型） | 連得到 Google Fonts
    kv_item("\u7db2\u8def\uff08\u5b57\u578b\uff09", "ok", "\u9023\u5f97\u5230 Google Fonts")
  } else {
    # 原文：網路（字型） | 連不到 Google Fonts：app 可以用，但字型會是電腦內建的
    kv_item("\u7db2\u8def\uff08\u5b57\u578b\uff09", "note", "\u9023\u4e0d\u5230 Google Fonts\uff1aapp \u53ef\u4ee5\u7528\uff0c\u4f46\u5b57\u578b\u6703\u662f\u96fb\u8166\u5167\u5efa\u7684")
  }
  do.call(rbind, out)
}

#' Linux：哪些系統函式庫找不到（用 ldd 看每個套件的 .so）
#'
#' 回傳具名 list：名稱是找不到的函式庫（例如 `libuv.so.1`），值是需要它的套件。
#' @noRd
kv_missing_syslibs <- function(pkgs) {
  if (!nzchar(Sys.which("ldd"))) return(list())
  miss <- list()
  for (p in pkgs) {
    dir <- system.file("libs", package = p)
    if (!nzchar(dir)) next
    for (so in list.files(dir, pattern = "\\.so$", full.names = TRUE, recursive = TRUE)) {
      out <- suppressWarnings(system2("ldd", shQuote(so), stdout = TRUE, stderr = TRUE))
      lost <- sub("^\\s*(\\S+)\\s*=>\\s*not found.*$", "\\1", grep("not found", out, value = TRUE))
      for (l in lost) miss[[l]] <- union(miss[[l]], p)
    }
  }
  miss
}

#' 系統函式庫的檔名換成 apt 的套件名稱（猜不到的照原樣）
#' @noRd
kv_apt_name <- function(miss) {
  known <- c("libuv.so.1" = "libuv1", "libicuuc" = "libicu-dev", "libicui18n" = "libicu-dev",
             "libxml2.so.2" = "libxml2", "libcurl.so.4" = "libcurl4", "libssl.so.3" = "libssl3",
             "libfontconfig.so.1" = "libfontconfig1", "libfreetype.so.6" = "libfreetype6",
             "libpng16.so.16" = "libpng16-16", "libharfbuzz.so.0" = "libharfbuzz0b",
             "libfribidi.so.0" = "libfribidi0", "libgfortran.so.5" = "libgfortran5")
  out <- vapply(names(miss), function(l) {
    hit <- names(known)[startsWith(l, names(known))]
    if (length(hit)) known[[hit[1]]] else sub("\\.so.*$", "", l)
  }, character(1))
  unique(unname(out))
}

#' app 的 log 裡最有用的幾行：錯誤訊息（沒有時是最後幾行）
#' @noRd
kv_log_errors <- function(lines, n = 8) {
  lines <- lines[!grepl("^\\s*[0-9]+: ", lines)]  # 呼叫堆疊（traceback）不用看
  err <- grep("error|Error|cannot|unable|not found", lines, value = TRUE)
  utils::tail(if (length(err)) err else lines, n)
}

#' 在另一個 R 裡載入套件，回傳錯誤訊息（都載得起來時是空的）
#' @noRd
kv_try_load <- function(pkgs) {
  script <- tempfile("kitverse-load-", fileext = ".R")
  log <- tempfile("kitverse-load-", fileext = ".log")
  on.exit(unlink(c(script, log)), add = TRUE)
  writeLines(c(
    sprintf(".libPaths(%s)", kv_deparse(.libPaths())),
    sprintf("for (p in %s) tryCatch(suppressPackageStartupMessages(loadNamespace(p)),", kv_deparse(pkgs)),
    "  error = function(e) cat(p, ': ', conditionMessage(e), '\\n', sep = ''))"
  ), script)
  system2(kv_rscript(), shQuote(script), stdout = log, stderr = log)
  out <- readLines(log, warn = FALSE, encoding = "UTF-8")
  out[nzchar(trimws(out))]
}

#' 連不連得到某個網址
#' @noRd
kv_online <- function(url) {
  h <- tryCatch(suppressWarnings(curlGetHeaders(url, timeout = 10)), error = function(e) NULL)
  !is.null(h) && attr(h, "status") < 400
}

#' 在另一個 R 裡開 app（不開瀏覽器），等網頁回來，再關掉
#' @noRd
kv_check_app <- function(app, timeout = 120) {
  port <- kv_free_port()
  pidfile <- tempfile("kitverse-pid-")
  log <- tempfile("kitverse-app-", fileext = ".log")
  script <- tempfile("kitverse-app-", fileext = ".R")
  on.exit(unlink(c(pidfile, script)), add = TRUE)
  writeLines(c(
    sprintf(".libPaths(%s)", kv_deparse(.libPaths())),
    sprintf("writeLines(as.character(Sys.getpid()), %s)", kv_deparse(pidfile)),
    sprintf("%s::%s(launch.browser = FALSE, host = '127.0.0.1', port = %dL)", app$pkg, app$run, port)
  ), script)
  t0 <- Sys.time()
  system2(kv_rscript(), shQuote(script), stdout = log, stderr = log, wait = FALSE)
  url <- sprintf("http://127.0.0.1:%d/", port)
  ok <- FALSE
  while (as.numeric(difftime(Sys.time(), t0, units = "secs")) < timeout) {
    Sys.sleep(1)
    page <- tryCatch(suppressWarnings(readLines(url, warn = FALSE)), error = function(e) NULL)
    if (!is.null(page) && any(grepl("shiny", page, fixed = TRUE))) {
      ok <- TRUE
      break
    }
  }
  secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")))
  if (file.exists(pidfile)) tools::pskill(as.integer(readLines(pidfile, warn = FALSE)[1]))
  if (ok) {
    unlink(log)
    # 原文：開啟  |  秒開好
    kv_item(paste0("\u958b\u555f ", app$name), "ok", paste0(secs, " \u79d2\u958b\u597d"))
  } else {
    tail_log <- kv_log_errors(readLines(log, warn = FALSE, encoding = "UTF-8"))
    # 原文：開啟 
    kv_item(paste0("\u958b\u555f ", app$name), "fail",
            # 原文： 秒內沒有開好。最後的訊息：\n    
            paste0(timeout, " \u79d2\u5167\u6c92\u6709\u958b\u597d\u3002\u6700\u5f8c\u7684\u8a0a\u606f\uff1a\n    ", paste(tail_log, collapse = "\n    ")))
  }
}

#' 一個沒有人用的 port
#' @noRd
kv_free_port <- function() {
  port <- tryCatch(httpuv::randomPort(), error = function(e) NULL)
  if (is.null(port)) port <- sample(49152:65000, 1)
  as.integer(port)
}

#' 印出檢查結果
#' @noRd
kv_print_check <- function(res) {
  # 原文：✓ | ✗
  mark <- c(ok = "\u2713", fail = "\u2717", note = "!")
  # 原文： 的檢查\n\n
  cat("\n kitverse ", kv_installed_version("kitverse"), " \u7684\u6aa2\u67e5\n\n", sep = "")
  for (i in seq_len(nrow(res))) {
    # 原文：：
    cat(" ", mark[[res$status[i]]], " ", res$item[i], "\uff1a", res$detail[i], "\n", sep = "")
  }
  n_fail <- sum(res$status == "fail")
  cat("\n")
  if (n_fail == 0) {
    # 原文： ✓ 都沒問題。開 app：kitverse::kitsui() 或 kitverse::kitjoin()\n\n
    cat(" \u2713 \u90fd\u6c92\u554f\u984c\u3002\u958b app\uff1akitverse::kitsui() \u6216 kitverse::kitjoin()\n\n")
  } else {
    # 原文： ✗ 有  |  項要處理（上面打 ✗ 的）。請把這個畫面截圖給助教。\n\n
    cat(" \u2717 \u6709 ", n_fail, " \u9805\u8981\u8655\u7406\uff08\u4e0a\u9762\u6253 \u2717 \u7684\uff09\u3002\u8acb\u628a\u9019\u500b\u756b\u9762\u622a\u5716\u7d66\u52a9\u6559\u3002\n\n", sep = "")
  }
}
