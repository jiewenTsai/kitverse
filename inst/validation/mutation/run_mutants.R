# Minimal mutation-testing runner (no external tools).
# Usage:
#   Rscript run_mutants.R check            # only verify every mutant applies on its line
#   Rscript run_mutants.R run [pkg] [ids]  # run mutants (optionally one package / comma ids)
# Mutates ONLY the scratch copies under work/<pkg>; each source file is restored from an
# in-memory copy after every mutant (and on exit). Results are appended to results_raw.tsv.
root <- Sys.getenv("KIT_MUTATION_DIR", getwd())   # mutants.csv and work/<package> (source copies)
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) >= 1) args[1] else "check"
mut <- utils::read.csv(file.path(root, "mutants.csv"), stringsAsFactors = FALSE)
if (length(args) >= 2 && args[2] != "all") mut <- mut[mut$package == args[2], ]
if (length(args) >= 3) mut <- mut[mut$mutant_id %in% strsplit(args[3], ",")[[1]], ]

src_path <- function(r) file.path(root, "work", r$package, "R", r$file)

apply_mutant <- function(lines, r) {
  ln <- lines[r$line]
  if (!grepl(r$original, ln, fixed = TRUE)) stop(r$mutant_id, ": original not found on line ", r$line,
                                                  " of ", r$file, ": ", ln)
  pos <- regexpr(r$original, ln, fixed = TRUE)
  lines[r$line] <- paste0(substr(ln, 1, pos - 1), r$mutant,
                          substr(ln, pos + attr(pos, "match.length"), nchar(ln)))
  lines
}

run_tests <- function(pkg, filt, tag) {
  out <- file.path(root, "logs", paste0(tag, ".txt"))
  unlink(out)
  system2("Rscript", c(file.path(root, "run_tests.R"), file.path(root, "work", pkg), shQuote(filt), out),
          stdout = file.path(root, "logs", paste0(tag, ".log")), stderr = file.path(root, "logs", paste0(tag, ".log")))
  if (!file.exists(out)) return(list(status = "no_output", n_bad = NA, files = "", secs = NA))
  f <- strsplit(readLines(out)[1], "\t")[[1]]
  list(status = f[1], n_bad = suppressWarnings(as.integer(f[2])), files = f[3], secs = as.numeric(f[4]))
}

for (i in seq_len(nrow(mut))) {
  r <- mut[i, ]
  p <- src_path(r)
  orig <- readLines(p, warn = FALSE, encoding = "UTF-8")
  mutated <- apply_mutant(orig, r)
  if (mode == "check") {
    cat(r$mutant_id, "OK:", trimws(mutated[r$line]), "\n")
    next
  }
  # parse check (compiles?)
  ok_parse <- tryCatch({ parse(text = mutated); TRUE }, error = function(e) FALSE)
  writeLines(mutated, p, useBytes = TRUE)
  t0 <- Sys.time()
  res <- tryCatch({
    if (!ok_parse) list(status = "parse_error", n_bad = NA, files = "PARSE", secs = 0, pass = "parse") else {
      a <- run_tests(r$package, r$test_filter, paste0(r$mutant_id, "_targeted"))
      a$pass <- "targeted"
      if (!(a$status != "ok" || isTRUE(a$n_bad > 0))) {
        b <- run_tests(r$package, "ALL", paste0(r$mutant_id, "_full"))
        b$pass <- "full"
        a <- b
      }
      a
    }
  }, finally = writeLines(orig, p, useBytes = TRUE))   # restore the original line
  stopifnot(identical(readLines(p, warn = FALSE, encoding = "UTF-8"), orig))
  secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
  killed <- res$status != "ok" || isTRUE(res$n_bad > 0)
  killer <- if (!killed) "" else if (res$status != "ok") paste0("[", res$status, "] ", res$files) else res$files
  row <- data.frame(mutant_id = r$mutant_id, package = r$package, error_type = r$error_type,
                    killed = killed, killing_test = killer, seconds = secs, decided_in = res$pass)
  rf <- file.path(root, paste0("results_raw_", r$package, ".tsv"))
  utils::write.table(row, rf, sep = "\t", row.names = FALSE, quote = FALSE,
                     col.names = !file.exists(rf), append = file.exists(rf))
  cat(format(Sys.time()), r$mutant_id, "killed =", killed, killer, secs, "s\n")
}
