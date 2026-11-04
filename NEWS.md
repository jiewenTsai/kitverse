# kitverse 0.5.8

* `kitverse_validation()` lists the validation reports of kitverse and its core packages, or opens
  one (`kitverse_validation("kits")`, or `"criteria"` for the standard).
* `inst/validation/`: the cross-package validation (metamorphic relations of kits, kitsUI and
  kitJoin, the mutation runner and results, the fault history of the five packages).
* Needs kits 0.26.1, kitsUI 0.8.8, kitJoin 0.10.2 and kitDesign 0.8.0.

# kitverse 0.5.7

* Needs kitsUI 0.8.7: the downloaded R code of a round gives the same result as the app when an
  item has a score category problem (before, `kits_item()` stopped there, e.g. with only M03 3 and
  36 months picked). `kitverse_check()` and the update shortcut bring an older kitsUI up to date.

# kitverse 0.5.6

* Needs kits 0.26.0: its demo data `kitm03` now has the real M03 children's aggregates at 60 and 72
  months (before, these two waves borrowed the M36 ones). `kitverse_check()` and the update shortcut
  bring an older kits up to date.

# kitverse 0.5.5

* `kitverse_shortcuts()` works on a Windows whose system language is not Chinese: the shortcuts are saved
  under an ASCII name and then renamed (Windows' shortcut maker cannot save a Chinese name there, "Unable
  to save shortcut"), and the paths come back to R as UTF-8. Found by the clean-Windows install test, where
  installing R and every package took about one minute.

# kitverse 0.5.4

R that has become too old. r-universe and CRAN build Windows packages only for CRAN's current and previous R
release; on an older R, updating needs Rtools to compile, which participants do not have.

* `windows/install.ps1` installs the latest R also when the R it finds is older than CRAN's previous release
  (read from CRAN's `VERSION-INFO.dcf`; 4.2 when CRAN cannot be reached). The old R stays; the packages are
  installed for the new R and the desktop shortcuts point at it.
* The update shortcut checks the same first; when R is too old it updates nothing and says to paste the
  install line again.
* `kitverse_check()` notes an R older than CRAN's previous release.

# kitverse 0.5.3

* The update shortcut and `install.R` install kitverse only when the repository has a newer version: a
  newer kitverse installed from GitHub was replaced by the older one on r-universe, which had no
  `kitverse_shortcuts()`, and the update stopped with an error.
* The update shortcut skips remaking the shortcuts when the installed kitverse cannot make them.
* `kitverse_pandoc()`: when the download fails (for example "SSL connect error", which some antivirus
  programs cause), Windows tries again with its own connection (wininet), and the message says what to do.

# kitverse 0.5.2

* `kitverse_pandoc()` (and so `kitverse_update()` and the update shortcut) uses the pandoc that RStudio or
  Quarto installed before downloading one. R started outside RStudio (the desktop shortcuts) did not know
  about RStudio's pandoc and downloaded 20–40 MB that the computer already had.

# kitverse 0.5.1

* A third desktop shortcut, "KIT 工具更新" (KIT tools update): double-click it (with the apps closed) to
  install the newest kitverse, update every package to its newest version (`kitverse_update(all = TRUE)`)
  and remake the shortcuts. The window waits for Enter so the result can be read. The app shortcuts never
  update by themselves.
* `windows/install.ps1`: only `R-x.y.z` folders count when looking for R (another folder such as `bin` next
  to them printed an error).

# kitverse 0.5.0

* Windows installer: `irm https://raw.githubusercontent.com/jiewenTsai/kitverse/main/windows/install.ps1 | iex`
  in PowerShell finds R 4.2 or newer (or installs the latest R from CRAN, silently), runs `install.R`, and
  ends with desktop shortcuts. Participants need neither RStudio nor to type R code.
* `kitverse_shortcuts()`: on Windows, a desktop shortcut for each app (named after the tool in Chinese),
  running this R's `Rscript.exe -e "kitsUI::run_kitsui()"` (or `run_kitjoin()`). `install.R` calls it at the end.
* Internal helpers are renamed from `kv_*` to `ktv_*`.

# kitverse 0.4.6

* `R CMD check` has no NOTE: kitverse imports the core packages only so that installing kitverse installs
  them, and the check wanted each of them used in the code. An internal function that is never called now
  names one function from each (`kv_imports()`), so loading kitverse still loads none of them.

# kitverse 0.4.5

* Needs kitDesign 0.7.1, kitsUI 0.8.4 and kitJoin 0.7.6. The app headers list the main packages first
  and the date last, each version with a "v": "kitsUI v0.8.4 · kits v0.25.2 · 2026-11-02",
  "kitJoin v0.7.6 · 2026-11-02".

# kitverse 0.4.4

* Needs kitDesign 0.7.0, kitsUI 0.8.3 and kitJoin 0.7.5. kitDesign 0.7.0 only adds components
  (`kit_dt()`, `kit_scope_bar()`, for kitItemBank 0.2.0); nothing changes on screen.

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
