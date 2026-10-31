#' kitverse：一次裝好、一行打開 KIT 的研究工具
#'
#' 裝 kitverse 就會裝好 kits、kitsUI、kitJoin、kitDesign 和它們需要的所有套件。
#'
#' - [kitsui()]、[kitjoin()]：開 app。
#' - [kitverse_check()]：檢查這台電腦（R、套件、真的把 app 開起來試）。
#' - [kitverse_update()]：裝缺少的、更新太舊的套件。
#' - [kitverse_requirements()]：要哪些套件、版本。
#' - [kitverse_repos()]：從哪裡裝。
#'
#' 安裝（Windows、macOS 不用 Rtools 或 Xcode）：
#'
#' ```r
#' install.packages("kitverse", repos = c("https://jiewentsai.r-universe.dev",
#'                                        "https://cloud.r-project.org"))
#' kitverse::kitverse_update()
#' kitverse::kitverse_check()
#' ```
#'
#' @keywords internal
"_PACKAGE"
