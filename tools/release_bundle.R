# Publish a KIT release: the five KIT packages as source tarballs in one GitHub release of kitverse
#
#   Rscript tools/release_bundle.R kit-2026.11.06
#
# Run it in the kitverse folder after the versions to ship are pushed to GitHub (main of each
# repository). It needs git, the GitHub CLI (gh, logged in) and R. It
# 1. clones main of kitDesign, kits, kitJoin, kitsUI and kitverse and builds each with R CMD build;
# 2. creates the GitHub release <tag> of jiewenTsai/kitverse with the five tarballs, and puts the
#    same files on the branch kit-release (raw.githubusercontent.com, which more computers reach);
# 3. writes bundle/kit-bundle.dcf (package, version, download addresses, what it needs).
# Then commit and push bundle/kit-bundle.dcf: from that moment install.R, kitverse_update() and
# kitverse_check() use this release whenever r-universe is behind it.

args <- commandArgs(trailingOnly = TRUE)
tag <- if (length(args) >= 1) args[1] else format(Sys.Date(), "kit-%Y.%m.%d")
owner <- "jiewenTsai"
pkgs <- c("kitDesign", "kits", "kitJoin", "kitsUI", "kitverse")
if (!file.exists("DESCRIPTION") || read.dcf("DESCRIPTION", "Package")[1, 1] != "kitverse") {
  stop("Run this in the kitverse folder.", call. = FALSE)
}

work <- file.path(tempdir(), "kit-release")
dir.create(work, recursive = TRUE, showWarnings = FALSE)
run <- function(cmd, args, wd = NULL) {
  old <- if (!is.null(wd)) setwd(wd)
  on.exit(if (!is.null(old)) setwd(old))
  status <- system2(cmd, args)
  if (!identical(status, 0L)) stop(cmd, " ", paste(args, collapse = " "), " failed", call. = FALSE)
}

rows <- lapply(pkgs, function(p) {
  src <- file.path(work, p)
  unlink(src, recursive = TRUE)
  run("git", c("clone", "--quiet", "--depth", "1", sprintf("https://github.com/%s/%s", owner, p), src))
  run(file.path(R.home("bin"), "R"), c("CMD", "build", "--no-build-vignettes", "--no-manual", p),
      wd = work)
  d <- read.dcf(file.path(src, "DESCRIPTION"), fields = c("Version", "Depends", "Imports", "LinkingTo"))
  file <- sprintf("%s_%s.tar.gz", p, d[1, "Version"])
  if (!file.exists(file.path(work, file))) stop("R CMD build did not make ", file, call. = FALSE)
  needs <- paste(stats::na.omit(d[1, c("Depends", "Imports", "LinkingTo")]), collapse = ", ")
  needs <- gsub("\\s+", " ", needs)
  data.frame(Tag = tag, Package = p, Version = d[1, "Version"],
             URL = sprintf("https://github.com/%s/kitverse/releases/download/%s/%s", owner, tag, file),
             Needs = needs, file = file.path(work, file), stringsAsFactors = FALSE)
})
rel <- do.call(rbind, rows)

notes <- paste0(
  "KIT release ", tag, ": ", paste(rel$Package, rel$Version, collapse = ", "), ".\n\n",
  "Install or update everything with the usual line (Windows: `irm https://raw.githubusercontent.com/",
  owner, "/kitverse/main/windows/install.ps1 | iex`; R: `source(\"https://raw.githubusercontent.com/",
  owner, "/kitverse/main/install.R\")`). It uses these files when r-universe is behind."
)
run("gh", c("release", "create", tag, rel$file, "--repo", paste0(owner, "/kitverse"),
            "--title", shQuote(paste("KIT release", tag)), "--notes", shQuote(notes)))

# The same files on the branch kit-release, served by raw.githubusercontent.com: some Windows
# computers cannot open github.com's release downloads from R ("SSL connect error"; github.com uses a
# newer Sectigo root those computers' R does not know), but they do reach raw.githubusercontent.com.
# The branch keeps one commit with only the current files.
branch_dir <- file.path(work, "kit-release-branch")
unlink(branch_dir, recursive = TRUE)
dir.create(branch_dir)
file.copy(rel$file, branch_dir)
writeLines(paste0("KIT release ", tag, ": ", paste(basename(rel$file), collapse = ", ")),
           file.path(branch_dir, "README.md"))
run("git", c("init", "--quiet", "-b", "kit-release"), wd = branch_dir)
run("git", c("add", "."), wd = branch_dir)
run("git", c("-c", "user.name=kitverse", "-c", "user.email=kitverse@users.noreply.github.com",
             "commit", "--quiet", "-m", shQuote(paste("KIT release", tag))), wd = branch_dir)
run("git", c("push", "--quiet", "--force", sprintf("https://github.com/%s/kitverse", owner),
             "kit-release"), wd = branch_dir)
rel$Mirror <- rel$URL
rel$URL <- sprintf("https://raw.githubusercontent.com/%s/kitverse/kit-release/%s", owner,
                   basename(rel$file))

dir.create("bundle", showWarnings = FALSE)
write.dcf(rel[, c("Tag", "Package", "Version", "URL", "Mirror", "Needs")], "bundle/kit-bundle.dcf",
          width = 1000)
cat("Release ", tag, " created. Now commit and push bundle/kit-bundle.dcf:\n",
    "  git add bundle/kit-bundle.dcf && git commit -m 'KIT release ", tag, "' && git push\n", sep = "")
