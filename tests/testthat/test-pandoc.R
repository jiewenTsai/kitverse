test_that("ktv_pandoc_asset() picks the release file for each computer", {
  v <- ktv_pandoc_version()
  expect_equal(ktv_pandoc_asset("Windows", "x86-64"), paste0("pandoc-", v, "-windows-x86_64.zip"))
  expect_equal(ktv_pandoc_asset("Darwin", "arm64"), paste0("pandoc-", v, "-arm64-macOS.zip"))
  expect_equal(ktv_pandoc_asset("Darwin", "x86_64"), paste0("pandoc-", v, "-x86_64-macOS.zip"))
  expect_equal(ktv_pandoc_asset("Linux", "x86_64"), paste0("pandoc-", v, "-linux-amd64.tar.gz"))
  expect_equal(ktv_pandoc_asset("Linux", "aarch64"), paste0("pandoc-", v, "-linux-arm64.tar.gz"))
  expect_null(ktv_pandoc_asset("SunOS", "sparc"))
})

test_that("ktv_renviron_set() adds or replaces one line and keeps the others", {
  f <- tempfile()
  writeLines(c("FOO=1", "RSTUDIO_PANDOC=/old"), f)
  ktv_renviron_set("RSTUDIO_PANDOC", "/new/bin", file = f)
  expect_equal(readLines(f), c("FOO=1", "RSTUDIO_PANDOC=\"/new/bin\""))
  g <- tempfile()
  ktv_renviron_set("RSTUDIO_PANDOC", "/x", file = g)
  expect_equal(readLines(g), "RSTUDIO_PANDOC=\"/x\"")
})

test_that("ktv_pandoc_bin() finds pandoc inside an unpacked release", {
  d <- tempfile()
  dir.create(file.path(d, "pandoc-3.7.0.2", "bin"), recursive = TRUE)
  exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  file.create(file.path(d, "pandoc-3.7.0.2", "bin", exe))
  expect_match(ktv_pandoc_bin(d), paste0("bin/", exe, "$"))
  expect_null(ktv_pandoc_bin(tempfile()))
})
