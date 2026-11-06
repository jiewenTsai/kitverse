# The KIT release on GitHub (R/bundle.R): reading the list, deciding what comes from it

write_release <- function(path, versions) {
  rel <- data.frame(
    Tag = "kit-test", Package = names(versions), Version = unname(versions),
    URL = paste0("https://example.org/", names(versions), "_", versions, ".tar.gz"),
    Needs = "R (>= 4.1.0), shiny (>= 1.8.0), cli", stringsAsFactors = FALSE
  )
  write.dcf(rel, path, width = 1000)
  path
}

test_that("kitverse_release() reads the list; a missing list gives NULL", {
  f <- write_release(withr::local_tempfile(fileext = ".dcf"), c(kitDesign = "0.8.0", kits = "9.9.9"))
  rel <- kitverse_release(f)
  expect_equal(rel$pkg, c("kitDesign", "kits"))
  expect_equal(rel$version, c("0.8.0", "9.9.9"))
  expect_equal(rel$tag, c("kit-test", "kit-test"))
  expect_match(rel$needs[1], "shiny")
  expect_null(kitverse_release(file.path(tempdir(), "no-such-list.dcf")))
})

test_that("only KIT packages the repository has in an older version come from the release", {
  f <- write_release(withr::local_tempfile(fileext = ".dcf"),
                     c(kitDesign = "0.8.0", kits = "0.26.1", kitJoin = "0.11.1"))
  rel <- kitverse_release(f)
  repo <- withr::local_tempdir()
  contrib <- file.path(repo, "src", "contrib")
  dir.create(contrib, recursive = TRUE)
  write.dcf(data.frame(Package = c("kitDesign", "kits"), Version = c("0.8.0", "0.26.0")),
            file.path(contrib, "PACKAGES"))
  repos <- c(kitverse = paste0("file://", repo))
  # kits is behind (0.26.0 < 0.26.1), kitJoin is missing; kitDesign is current
  expect_equal(ktv_bundle_needed(rel, repos), c("kits", "kitJoin"))
  expect_equal(ktv_bundle_needed(rel, repos, "kitDesign"), character(0))
  expect_equal(ktv_bundle_needed(NULL, repos), character(0))
})

test_that("the check line says whether the KIT packages are the current release", {
  have <- as.character(utils::packageVersion("kitverse"))
  f <- write_release(withr::local_tempfile(fileext = ".dcf"), c(kitverse = have))
  ok <- ktv_check_release(kitverse_release(f))
  expect_equal(ok$status, "ok")
  expect_match(ok$detail, "kit-test")
  f2 <- write_release(withr::local_tempfile(fileext = ".dcf"), c(kitverse = "99.0.0"))
  behind <- ktv_check_release(kitverse_release(f2))
  expect_equal(behind$status, "note")
  expect_match(behind$detail, "kitverse 99.0.0")
  expect_equal(ktv_behind_release(kitverse_release(f2)), "kitverse")
  expect_equal(ktv_check_release(NULL)$status, "note")
})
