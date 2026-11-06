# Before a workshop: are GitHub, r-universe, the KIT release and this computer on the same versions?
#
#   Rscript tools/check_versions.R
#
# One row per KIT package: the version on GitHub (main), on r-universe, in the KIT release
# (bundle/kit-bundle.dcf on GitHub) and installed here. "ok" when all four agree.
# What to do when they do not:
# - r-universe behind GitHub: wait (it rebuilds within about an hour of a push); if it stays
#   behind, look at https://github.com/r-universe/jiewentsai/actions. Participants still get the
#   right version from the KIT release, as long as the release is current.
# - release behind GitHub: Rscript tools/release_bundle.R <new tag>, then push bundle/kit-bundle.dcf.
# - installed behind: kitverse::kitverse_update(all = TRUE).

owner <- "jiewenTsai"
pkgs <- c("kitDesign", "kits", "kitJoin", "kitsUI", "kitverse")
options(timeout = 30)
read_remote_dcf <- function(u, fields) {
  tryCatch({
    con <- url(u)
    on.exit(close(con))
    read.dcf(con, fields = fields)
  }, error = function(e) NULL, warning = function(w) NULL)
}
github <- vapply(pkgs, function(p) {
  d <- read_remote_dcf(sprintf("https://raw.githubusercontent.com/%s/%s/main/DESCRIPTION", owner, p),
                       "Version")
  if (is.null(d)) NA_character_ else d[1, 1]
}, character(1))
ap <- tryCatch(available.packages(repos = "https://jiewentsai.r-universe.dev"), error = function(e) NULL)
universe <- vapply(pkgs, function(p) {
  if (is.null(ap) || !p %in% rownames(ap)) NA_character_ else ap[p, "Version"]
}, character(1))
rel <- read_remote_dcf(sprintf("https://raw.githubusercontent.com/%s/kitverse/main/bundle/kit-bundle.dcf",
                               owner), c("Tag", "Package", "Version"))
release <- vapply(pkgs, function(p) {
  if (is.null(rel) || !p %in% rel[, "Package"]) NA_character_ else rel[rel[, "Package"] == p, "Version"]
}, character(1))
installed <- vapply(pkgs, function(p) {
  tryCatch(as.character(packageVersion(p)), error = function(e) NA_character_)
}, character(1))
tab <- data.frame(package = pkgs, github = github, r_universe = universe, release = release,
                  installed = installed, row.names = NULL, stringsAsFactors = FALSE)
same <- apply(tab[, -1], 1, function(v) !anyNA(v) && length(unique(v)) == 1)
tab$status <- ifelse(same, "ok", "CHECK")
if (!is.null(rel)) cat("KIT release:", rel[1, "Tag"], "\n")
print(tab, right = FALSE)
if (all(same)) cat("\nAll the same: participants will get these versions.\n")
