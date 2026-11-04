# Usage: Rscript run_tests.R <pkg_dir> <filter-regex or ALL> <out_file>
# Runs the testthat suite of a (copied) package via pkgload/testthat::test_local
# and writes one line: status<TAB>n_failed<TAB>failing_files<TAB>seconds
args <- commandArgs(trailingOnly = TRUE)
pkg <- args[1]
filt <- if (length(args) >= 2 && args[2] != "ALL") args[2] else NULL
out <- args[3]
Sys.setenv(NOT_CRAN = "true", TESTTHAT_PARALLEL = "false")
t0 <- Sys.time()
status <- "ok"
res <- tryCatch(
  testthat::test_local(pkg, filter = filt, reporter = testthat::SilentReporter$new(),
                       stop_on_failure = FALSE, stop_on_warning = FALSE,
                       load_package = "source"),
  error = function(e) { status <<- paste("load_error:", conditionMessage(e)); NULL })
secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
if (is.null(res)) {
  line <- paste(status, NA, "LOAD/ERROR", round(secs, 1), sep = "\t")
} else {
  df <- as.data.frame(res)
  bad <- df[df$failed > 0 | df$error, , drop = FALSE]
  files <- unique(bad$file)
  line <- paste(status, nrow(bad), paste(files, collapse = ";"), round(secs, 1),
                nrow(df), sum(df$skipped), sep = "\t")
}
writeLines(gsub("[\r\n]", " ", line), out)
cat(line, "\n")
