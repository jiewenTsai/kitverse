# 從哪裡裝：KIT 的套件從 r-universe，其他從 CRAN
#
# r-universe 是像 CRAN 一樣的套件庫，有 Windows 與 macOS 編好的版本，而且不經過 GitHub API
# （80 人在同一個會場用 remotes::install_github() 時，GitHub 每小時 60 次的限制會被用完）。
# Linux 的 CRAN 沒有編好的版本，從原始碼編 RTMB 要十幾分鐘：Ubuntu／Debian 改用
# Posit Package Manager 的 binary。

#' 安裝套件用的套件庫
#'
#' KIT 的套件從 r-universe（`https://jiewentsai.r-universe.dev`），其他套件從 CRAN；
#' 在 Ubuntu 與 Debian 上，CRAN 換成 Posit Package Manager 編好的版本。
#' 用 `options(kitverse.repo = )` 可以換掉 r-universe（例如工作坊現場的離線套件庫），
#' 用 `options(kitverse.cran = )` 可以換掉 CRAN。
#'
#' @return 具名的網址向量，可以直接給 `install.packages(repos = )`。
#' @examples
#' kitverse_repos()
#' @export
kitverse_repos <- function() {
  kit <- getOption("kitverse.repo", "https://jiewentsai.r-universe.dev")
  cran <- getOption("kitverse.cran", kv_default_cran())
  c(kitverse = kit, CRAN = cran)
}

#' 預設的 CRAN：Ubuntu／Debian 用 Posit Package Manager 的 binary，其他用 CRAN
#' @noRd
kv_default_cran <- function(os_release = "/etc/os-release") {
  cran <- "https://cloud.r-project.org"
  if (.Platform$OS.type != "unix" || Sys.info()[["sysname"]] != "Linux") return(cran)
  if (!file.exists(os_release)) return(cran)
  rel <- readLines(os_release, warn = FALSE)
  get <- function(key) {
    line <- grep(paste0("^", key, "="), rel, value = TRUE)
    if (length(line) == 0) "" else gsub("\"", "", sub("^[^=]*=", "", line[1]))
  }
  id <- get("ID")
  codename <- get("VERSION_CODENAME")
  if (!id %in% c("ubuntu", "debian") || !nzchar(codename)) return(cran)
  paste0("https://packagemanager.posit.co/cran/__linux__/", codename, "/latest")
}
