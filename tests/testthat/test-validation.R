test_that("kitverse_validation() lists the reports; opens one; refuses other packages", {
  tab <- kitverse_validation()
  expect_named(tab, c("package", "version", "file", "url"))
  expect_true("kits" %in% tab$package)
  expect_match(tab$url, "^https://github.com/.+/inst/validation/validation.md$")
  expect_true(file.exists(kitverse_validation("criteria", open = FALSE)))
  expect_error(kitverse_validation("stats"), "one of")
})
