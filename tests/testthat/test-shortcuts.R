test_that("ktv_shortcut_ps() makes a shortcut per app and one for updating, all running this R's Rscript", {
  ps <- ktv_shortcut_ps(ktv_shortcut_apps(), rscript = "C:/Program Files/R/R-4.6.2/bin/x64/Rscript.exe")
  expect_match(ps[2], "GetFolderPath('Desktop')", fixed = TRUE)
  expect_equal(sum(grepl("CreateShortcut", ps, fixed = TRUE)), 3)
  expect_true("$l.TargetPath = 'C:\\Program Files\\R\\R-4.6.2\\bin\\x64\\Rscript.exe'" %in% ps)
  expect_true("$l.Arguments = '-e \"kitsUI::run_kitsui()\"'" %in% ps)
  expect_true("$l.Arguments = '-e \"kitJoin::run_kitjoin()\"'" %in% ps)
  expect_true("$l.Arguments = '-e \"kitverse:::ktv_shortcut_update()\"'" %in% ps)
  expect_true(exists("ktv_shortcut_update", mode = "function"))
  # 檔名是工具的中文名稱：KIT 量尺建構工具、KIT 資料處理工具
  expect_true(any(grepl("KIT \u91cf\u5c3a\u5efa\u69cb\u5de5\u5177.lnk", ps, fixed = TRUE)))
  expect_true(any(grepl("KIT \u8cc7\u6599\u8655\u7406\u5de5\u5177.lnk", ps, fixed = TRUE)))
  # KIT 工具更新
  expect_true(any(grepl("KIT \u5de5\u5177\u66f4\u65b0.lnk", ps, fixed = TRUE)))
  expect_true(any(grepl("Rgui.exe,0", ps, fixed = TRUE)))
})

test_that("ktv_shortcut_ps() quotes paths for PowerShell and can use another folder", {
  ps <- ktv_shortcut_ps(ktv_shortcut_apps(), rscript = "C:/Users/O'Brien/R/bin/Rscript.exe",
                        dir = "D:/kit shortcuts")
  expect_equal(ps[2], "$dir = 'D:\\kit shortcuts'")
  expect_true("$l.TargetPath = 'C:\\Users\\O''Brien\\R\\bin\\Rscript.exe'" %in% ps)
})

test_that("ktv_write_utf8_bom() writes a BOM and UTF-8 with Windows line ends", {
  f <- tempfile(fileext = ".ps1")
  ktv_write_utf8_bom(c("a", "\u5de5\u5177"), f)
  bytes <- readBin(f, "raw", 100)
  expect_equal(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))
  expect_equal(rawToChar(bytes[-(1:3)]), enc2native("a\r\n\u5de5\u5177\r\n"))
})

test_that("kitverse_shortcuts() makes nothing outside Windows", {
  skip_on_os("windows")
  expect_message(res <- kitverse_shortcuts(), "only made on Windows")
  expect_length(res, 0)
})
