# Combine per-package raw results -> mutation_results.csv and print kill rates
root <- Sys.getenv("KIT_MUTATION_DIR", getwd())   # mutants.csv and work/<package> (source copies)
fs <- list.files(root, "^results_raw_.*\\.tsv$", full.names = TRUE)
res <- do.call(rbind, lapply(fs, utils::read.delim, stringsAsFactors = FALSE))
mut <- utils::read.csv(file.path(root, "mutants.csv"), stringsAsFactors = FALSE)
res <- res[match(mut$mutant_id, res$mutant_id), ]
res <- res[!is.na(res$mutant_id), ]
res <- res[!duplicated(res$mutant_id, fromLast = TRUE), ]
utils::write.csv(res, file.path(root, "mutation_results.csv"), row.names = FALSE)
rate <- function(g) {
  a <- aggregate(killed ~ g, data = data.frame(g = g, killed = res$killed),
                 FUN = function(k) sprintf("%d/%d (%.0f%%)", sum(k), length(k), 100 * mean(k)))
  print(a, row.names = FALSE)
}
rate(res$package); rate(res$error_type)
cat(sprintf("overall %d/%d\n", sum(res$killed), nrow(res)))
print(res[!res$killed, c("mutant_id", "package", "error_type", "seconds")], row.names = FALSE)
