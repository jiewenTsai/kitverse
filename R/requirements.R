# 要哪些套件、最低版本、裝了沒有
#
# 從 kitverse 自己的 DESCRIPTION 開始，一層一層讀已經裝好的套件的 DESCRIPTION
# （Depends、Imports、LinkingTo），把每個套件被要求的最低版本都記下來（取最高的那個）。
# 只讀 DESCRIPTION、不載入套件：版本太舊的套件一載入就會出錯，而 Windows 上
# 載入中的套件不能覆蓋。

# R 本身就有的套件：不用裝、不用檢查
kv_base_pkgs <- function() {
  c("R", rownames(utils::installed.packages(priority = "base")))
}

#' 解析 DESCRIPTION 的相依欄位：套件名稱與最低版本（沒有寫時是 NA）
#' @noRd
kv_parse_deps <- function(fields) {
  fields <- fields[!is.na(fields)]
  if (length(fields) == 0) {
    return(data.frame(pkg = character(0), min = character(0), stringsAsFactors = FALSE))
  }
  items <- trimws(unlist(strsplit(paste(fields, collapse = ","), ",")))
  items <- gsub("\\s+", " ", items[nzchar(items)])
  pkg <- sub("^([A-Za-z0-9.]+).*$", "\\1", items)
  min <- ifelse(grepl(">=", items), sub("^.*>=\\s*([0-9.-]+).*$", "\\1", items), NA_character_)
  data.frame(pkg = pkg, min = min, stringsAsFactors = FALSE)
}

#' 一個套件的 DESCRIPTION 相依欄位（沒有裝時是 NULL）
#' @noRd
kv_desc_deps <- function(pkg, lib.loc = NULL) {
  path <- system.file("DESCRIPTION", package = pkg, lib.loc = lib.loc)
  if (!nzchar(path)) return(NULL)
  d <- read.dcf(path, fields = c("Depends", "Imports", "LinkingTo"))[1, ]
  kv_parse_deps(d)
}

#' 已經裝的版本（沒裝時 NA）
#' @noRd
kv_installed_version <- function(pkg, lib.loc = NULL) {
  path <- system.file("DESCRIPTION", package = pkg, lib.loc = lib.loc)
  if (!nzchar(path)) return(NA_character_)
  unname(read.dcf(path, fields = "Version")[1, 1])
}

#' 兩個最低版本取高的（NA 表示沒有要求）
#' @noRd
kv_max_version <- function(a, b) {
  if (is.na(a)) return(b)
  if (is.na(b)) return(a)
  if (utils::compareVersion(a, b) >= 0) a else b
}

#' kitverse 要的所有套件
#'
#' 從 `roots`（預設是 kitverse 自己）出發，讀已經裝好的套件的 DESCRIPTION，找出所有
#' 直接與間接需要的套件、被要求的最低版本、裝了的版本。沒有裝的套件讀不到它的
#' DESCRIPTION，它底下的套件要等它裝好才看得到（[kitverse_update()] 會一直重複到沒有缺的）。
#'
#' @param roots 從哪些套件開始找。
#' @param lib.loc 套件資料夾（預設是 `.libPaths()`）。
#' @return data.frame：`pkg`（套件）、`min`（最低版本，沒有要求時 NA）、`have`（裝的版本，
#'   沒裝時 NA）、`ok`（有裝且版本夠新）、`why`（不 ok 的原因）。
#' @examples
#' req <- kitverse_requirements()
#' req[!req$ok, ]
#' @export
kitverse_requirements <- function(roots = "kitverse", lib.loc = NULL) {
  base <- kv_base_pkgs()
  need <- list()
  queue <- roots
  seen <- character(0)
  while (length(queue) > 0) {
    pkg <- queue[1]
    queue <- queue[-1]
    if (pkg %in% seen) next
    seen <- c(seen, pkg)
    deps <- kv_desc_deps(pkg, lib.loc)
    if (is.null(deps)) next
    deps <- deps[!deps$pkg %in% base, , drop = FALSE]
    for (i in seq_len(nrow(deps))) {
      p <- deps$pkg[i]
      old <- if (is.null(need[[p]])) NA_character_ else need[[p]]
      need[[p]] <- kv_max_version(old, deps$min[i])
    }
    queue <- c(queue, setdiff(deps$pkg, seen))
  }
  pkgs <- sort(names(need))
  min <- vapply(pkgs, function(p) need[[p]], character(1), USE.NAMES = FALSE)
  have <- vapply(pkgs, kv_installed_version, character(1), lib.loc = lib.loc, USE.NAMES = FALSE)
  too_old <- !is.na(have) & !is.na(min) &
    mapply(function(h, m) utils::compareVersion(h, m) < 0, have, ifelse(is.na(min), "0", min),
           USE.NAMES = FALSE)
  # 原文：沒有安裝
  why <- ifelse(is.na(have), "\u6c92\u6709\u5b89\u88dd",
                # 原文：版本太舊（ | ，需要  |  以上）
                ifelse(too_old, paste0("\u7248\u672c\u592a\u820a\uff08", have, "\uff0c\u9700\u8981 ", min, " \u4ee5\u4e0a\uff09"), ""))
  data.frame(pkg = pkgs, min = min, have = have, ok = !is.na(have) & !too_old, why = why,
             stringsAsFactors = FALSE)
}
