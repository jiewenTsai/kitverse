# 假的套件資料夾：每個套件只有一個 DESCRIPTION
fake_lib <- function(pkgs) {
  lib <- withr_tempdir()
  for (p in names(pkgs)) {
    dir.create(file.path(lib, p))
    fields <- c(Package = p, Version = pkgs[[p]]$version, Imports = pkgs[[p]]$imports %||% NA)
    fields <- fields[!is.na(fields)]
    write.dcf(as.data.frame(as.list(fields)), file.path(lib, p, "DESCRIPTION"))
  }
  lib
}
withr_tempdir <- function() {
  d <- tempfile("kvlib-")
  dir.create(d)
  d
}
`%||%` <- function(x, y) if (is.null(x)) y else x

test_that("kv_parse_deps() reads names and minimum versions", {
  d <- kv_parse_deps(c(Depends = "R (>= 4.1.0)", Imports = "bslib (>= 0.11.0),\n    shiny, kits(>= 0.25.2)"))
  expect_equal(d$pkg, c("R", "bslib", "shiny", "kits"))
  expect_equal(d$min, c("4.1.0", "0.11.0", NA, "0.25.2"))
  expect_equal(nrow(kv_parse_deps(c(Imports = NA))), 0)
})

test_that("kv_max_version() keeps the higher requirement", {
  expect_equal(kv_max_version(NA, "1.0"), "1.0")
  expect_equal(kv_max_version("0.11.0", "0.9.1"), "0.11.0")
  expect_equal(kv_max_version("0.11.0", NA), "0.11.0")
})

test_that("kitverse_requirements() follows dependencies and flags missing and old ones", {
  lib <- fake_lib(list(
    top = list(version = "1.0", imports = "a (>= 2.0), b"),
    a = list(version = "1.5", imports = "c (>= 0.3), utils"),
    b = list(version = "1.0", imports = "c (>= 0.5)")
  ))
  req <- kitverse_requirements("top", lib.loc = lib)
  expect_equal(req$pkg, c("a", "b", "c"))
  expect_equal(req$min, c("2.0", NA, "0.5"))
  expect_equal(req$ok, c(FALSE, TRUE, FALSE))
  expect_match(req$why[1], "1.5")
  expect_match(req$why[3], "沒有安裝")
})

test_that("kv_default_cran() uses Posit Package Manager on Ubuntu only", {
  skip_if_not(Sys.info()[["sysname"]] == "Linux")
  f <- tempfile()
  writeLines(c('ID=ubuntu', 'VERSION_CODENAME=noble'), f)
  expect_equal(kv_default_cran(f), "https://packagemanager.posit.co/cran/__linux__/noble/latest")
  writeLines(c('ID=fedora', 'VERSION_CODENAME='), f)
  expect_equal(kv_default_cran(f), "https://cloud.r-project.org")
  expect_equal(kv_default_cran(tempfile()), "https://cloud.r-project.org")
})

test_that("kitverse_repos() can be pointed at another repository", {
  old <- options(kitverse.repo = "file:///usb/repo", kitverse.cran = "https://cran.example")
  on.exit(options(old))
  expect_equal(kitverse_repos(), c(kitverse = "file:///usb/repo", CRAN = "https://cran.example"))
})
