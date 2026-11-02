test_that("ktv_print_check() marks each item and sums up", {
  res <- rbind(ktv_item("R", "ok", "4.6.1"), ktv_item("x", "fail", "bad"), ktv_item("y", "note", "hm"))
  out <- capture.output(ktv_print_check(res))
  expect_true(any(grepl("\u2714 R", out)))
  expect_true(any(grepl("\u2716 x", out)))
  expect_true(any(grepl("! y", out)))
  expect_true(any(grepl("1 item to fix", out)))
})

test_that("ktv_check_items() reports a missing package with the fix", {
  req <- data.frame(pkg = c("bslib", "shiny"), min = c("0.11.0", NA), have = c("0.10.0", "1.9"),
                    ok = c(FALSE, TRUE), why = c("too old", ""), stringsAsFactors = FALSE)
  res <- ktv_check_items(req)
  expect_equal(res$status[res$item == "Package versions"], "fail")
  expect_match(res$detail[res$item == "Package versions"], "kitverse_update")
  expect_equal(res$status[res$item == "Package loading"], "fail")
})

test_that("both apps start and answer (slow: really starts them)", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.getenv("KITVERSE_TEST_APPS")))
  for (app in ktv_apps()) {
    res <- ktv_check_app(app, timeout = 120)
    expect_equal(res$status, "ok", info = res$detail)
  }
})

test_that("ktv_log_errors() keeps the error lines, not the traceback", {
  log <- c("Listening on http://127.0.0.1:8123", "Warning: Error in dyn.load: unable to load shared object 'fs.so':",
           "  libuv.so.1: cannot open shared object file", "  14: rookCall", "   1: kitsUI::run_kitsui")
  out <- ktv_log_errors(log)
  expect_true(any(grepl("libuv", out)))
  expect_false(any(grepl("rookCall", out)))
})

test_that("ktv_apt_name() maps missing libraries to apt packages", {
  expect_equal(ktv_apt_name(list("libuv.so.1" = "fs")), "libuv1")
  expect_equal(ktv_apt_name(list("libfoo.so.2" = "x", "libuv.so.1" = "fs")), c("libfoo", "libuv1"))
})
