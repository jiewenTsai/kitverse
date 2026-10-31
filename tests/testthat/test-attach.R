test_that("kv_attach_message() lists packages in two columns like tidyverse", {
  res <- data.frame(pkg = c("kits", "kitsUI", "kitJoin", "kitDesign"),
                    version = c("0.25.2", "0.5.0", "0.6.0", "0.4.0"), ok = TRUE, why = "",
                    stringsAsFactors = FALSE)
  none <- structure(data.frame(name = character(0), winner = character(0), losers = character(0)),
                    class = c("kitverse_conflicts", "data.frame"))
  msg <- strsplit(kv_attach_message(res, conflicts = none), "\n")[[1]]
  expect_match(msg[1], "^\u2500\u2500 .* kitverse .* \u2500\u2500$")
  expect_match(msg[2], "\u2714 kits +0.25.2 +\u2714 kitJoin +0.6.0")
  expect_match(msg[3], "\u2714 kitsUI +0.5.0 +\u2714 kitDesign 0.4.0")
  expect_false(any(grepl("kitverse_conflicts", msg)))
})

test_that("kv_attach_message() shows broken packages and conflicts", {
  res <- data.frame(pkg = c("kits", "kitsUI"), version = c("0.25.2", "0.5.0"), ok = c(TRUE, FALSE),
                    why = c("", "bslib: too old"), stringsAsFactors = FALSE)
  cf <- structure(data.frame(name = "filter", winner = "kits", losers = "stats", stringsAsFactors = FALSE),
                  class = c("kitverse_conflicts", "data.frame"))
  msg <- kv_attach_message(res, conflicts = cf)
  expect_match(msg, "\u2716 kitsUI")
  expect_match(msg, "kitverse_update")
  expect_match(msg, "\u2716 kits::filter\\(\\) masks stats::filter\\(\\)")
})

test_that("kitverse_conflicts() finds a function that masks another", {
  e <- attach(list(kitverse_test_fn = function() 1), name = "package:kvfake", warn.conflicts = FALSE)
  on.exit(detach("package:kvfake"), add = TRUE)
  e2 <- attach(list(kitverse_test_fn = function() 2), name = "package:other", pos = 3,
               warn.conflicts = FALSE)
  on.exit(detach("package:other"), add = TRUE)
  cf <- kitverse_conflicts(only = "kvfake")
  expect_equal(cf$name, "kitverse_test_fn")
  expect_equal(cf$losers, "other")
  expect_match(capture.output(print(cf)), "kvfake::kitverse_test_fn")
})
