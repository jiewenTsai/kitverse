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

test_that("ktv_pandoc_existing() finds RStudio's or Quarto's pandoc, first folder first", {
  exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  a <- tempfile("rstudio-tools-")
  b <- tempfile("quarto-tools-")
  dir.create(a)
  dir.create(b)
  expect_null(ktv_pandoc_existing(c(a, b)))
  file.create(file.path(b, exe))
  expect_equal(ktv_pandoc_existing(c(a, b)), file.path(b, exe))
  file.create(file.path(a, exe))
  expect_equal(ktv_pandoc_existing(c(a, b)), file.path(a, exe))
})

test_that("ktv_pandoc_known_dirs() includes RStudio's bundled Quarto tools on Windows", {
  old <- Sys.getenv(c("ProgramFiles", "LOCALAPPDATA"), unset = NA)
  on.exit(for (n in names(old)) {
    if (is.na(old[[n]])) Sys.unsetenv(n) else do.call(Sys.setenv, as.list(old[n]))
  }, add = TRUE)
  Sys.setenv(ProgramFiles = "C:/Program Files", LOCALAPPDATA = "C:/Users/u/AppData/Local")
  dirs <- ktv_pandoc_known_dirs("Windows")
  expect_true("C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools" %in% dirs)
  expect_true("C:/Users/u/AppData/Local/Programs/Quarto/bin/tools" %in% dirs)
  expect_true(any(grepl("^/Applications/RStudio.app/", ktv_pandoc_known_dirs("Darwin"))))
})
