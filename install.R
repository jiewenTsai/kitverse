# kitverse 一行安裝：打開 R，貼上這一行
#
#   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
#
# 做三件事：
# 1. 建立個人的套件資料夾（剛裝好的 R 沒有，install.packages() 會跳出問題或失敗）；
# 2. 從 r-universe 安裝 kitverse 和所有需要的套件（Windows、macOS 是編好的版本，
#    不用 Rtools 或 Xcode；Ubuntu／Debian 從 Posit Package Manager 拿編好的版本）；
# 3. 更新已經裝了但太舊的套件，再檢查一次這台電腦（會把 kitsUI、kitJoin 真的開起來試）。
#
# 工作坊現場的離線套件庫：先 Sys.setenv(KITVERSE_REPO = "file:///…")，再 source() 這個檔。
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
    # Posit Package Manager 看 user agent 決定給哪個 R 版本的 binary
    HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
      paste(getRversion(), R.version[["platform"]], R.version[["arch"]], R.version[["os"]]))
  )

  lib <- path.expand(strsplit(Sys.getenv("R_LIBS_USER"), .Platform$path.sep, fixed = TRUE)[[1]][1])
  if (!is.na(lib) && nzchar(lib)) {
    dir.create(lib, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(lib, .libPaths()))
  }
  lib <- .libPaths()[1]

  message("== 1/3 安裝 kitverse（第一次約 3–10 分鐘，請不要關掉 R）")
  install.packages("kitverse", lib = lib, repos = repos)
  if (!requireNamespace("kitverse", quietly = TRUE)) {
    stop("kitverse 沒有裝好。請確認電腦連上網路，再貼一次這一行；還是不行請截圖給助教。",
         call. = FALSE)
  }
  message("== 2/3 更新太舊的套件")
  kitverse::kitverse_update()
  message("== 3/3 檢查這台電腦")
  kitverse::kitverse_check()
})
