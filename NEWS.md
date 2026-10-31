# kitverse 0.4.3

* Needs kitDesign 0.6.1, kitsUI 0.8.2 and kitJoin 0.7.4: in kitsUI, 「用這一回合的固定檔開始下一回合」
  updates ① again, and plots in closed sections no longer open squashed.

# kitverse 0.4.2

* Needs kitDesign 0.6.0, kitsUI 0.8.0 and kitJoin 0.7.3: the plot toolbar in kitsUI saves PNGs at
  2100 pixels / 300 dpi and SVGs for papers.

# kitverse 0.4.1

## Fixes

* Needs kitDesign 0.5.2, kitsUI 0.7.2 and kitJoin 0.7.2: downloads in the apps no longer fail with
  "Not Found" in Firefox with a "document viewer" add-on such as Google PDF Viewer (the download
  buttons are no longer links an add-on can take over). `kitverse_update()` installs them, and
  `library(kitverse)` says when an older one is installed.

# kitverse 0.4.0

## Changes you can see

* kitverse installs **pandoc** when R cannot find one. kitsUI saves plots as one html file, which
  needs pandoc; RStudio and Quarto come with it, but a computer with only R has none, so the plot
  downloads did not work in the local version. `kitverse_update()` (and `install.R`) now
  downloads pandoc 3.7.0.2 into kitverse's data folder and sets `RSTUDIO_PANDOC` in `~/.Renviron`,
  so every new R session finds it, however the app is started. New `kitverse_pandoc()` does this
  on its own. Pandoc comes from its GitHub release files (not the GitHub API).
* `kitverse_check()` has three new items: **Pandoc**; **Saving files**, which saves one file of
  each kind the apps offer (a plot as html the way kitsUI does, CSV, csv.gz, SAV, zip); and
  **PNG plots (optional)** for `kits::kits_save_plot(png = )`, which needs webshot2 and Chrome but
  is not used by the apps.

## Under the hood

* Quarto is not needed: kitsUI only looks in the RStudio and Quarto folders to find their pandoc.
  kitJoin and kitDesign call no outside programs; zip, SAV and CSV come from R packages.
* `Imports: rmarkdown` (htmlwidgets finds pandoc through it).

# kitverse 0.3.0

## Changes you can see

* Colors like tidyverse (with the cli package): ✔ green, ✖ red, package names blue, grey rules.
  Consoles without colors (for example Windows Rgui) get plain text.
* When this R session has an older version of a package loaded than the one installed (a package
  was updated while loaded), `library(kitverse)` and `kitverse_check()` say to restart R instead
  of running `kitverse_update()`. This also explains warnings such as
  "internal error ... in R_decompress1".

## Under the hood

* `Imports: cli` (already installed with dplyr and friends).

# kitverse 0.2.0

## Changes you can see

* Works like tidyverse: `library(kitverse)` attaches kits, kitsUI, kitJoin and kitDesign, and
  their own functions are used directly (`run_kitsui()` from kitsUI, `run_kitjoin()` from
  kitJoin). `kitsui()` and `kitjoin()` are gone; kitverse only exports the `kitverse_*()` helpers.
* `library(kitverse)` prints like tidyverse: a rule with the kitverse version, the core packages
  in two columns with ✔ and their versions, and the conflicts. A package that is missing, too old
  or fails to load gets ✖, the reason and "Run kitverse::kitverse_update()"; the others still
  load (for example kits loads when only bslib is too old).
* New `kitverse_conflicts()`: core functions that mask functions in other attached packages
  (kitsUI and kitJoin both export `kit_app()`).
* All messages are in English.
* README: a table with each package's GitHub link; kitJoin is 「KIT 資料處理工具」.

## Under the hood

* Requires kitDesign 0.5.0, kitsUI 0.6.0 and kitJoin 0.7.0. `Remotes:` points at
  `jiewenTsai/kitDesign@v0.5.0`, the same tag as both apps (two refs for one package make pak
  stop with "dependency conflict").

# kitverse 0.1.0

* First version. Installing kitverse installs kits, kitsUI, kitJoin, kitDesign and everything
  they need; loading the kitverse namespace loads none of them, so the check and the update still
  work when a package is broken.
* `kitverse_check()`: R, package library, versions, loading, Linux system libraries (`ldd`, with
  the `sudo apt install` to run), temporary folder and fonts; then really starts both apps.
* `kitverse_update()`: installs missing and too-old packages in a separate R.
* `install.R`: the one line for workshop participants (personal library, r-universe, Posit
  Package Manager on Ubuntu/Debian, update, check).
* CI: R CMD check on Linux, Windows and macOS (starts both apps), and a manual install test from
  r-universe.
