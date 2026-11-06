# kitverse

English | [繁體中文](README.zh-TW.md)

Install the KIT research tools in one step and open them with one line. Installing kitverse installs:

| Package | What it is | GitHub |
|---|---|---|
| **kits** | Item calibration, linking across cohorts, scoring | [jiewenTsai/kits](https://github.com/jiewenTsai/kits) |
| **kitsUI** | KIT 量尺建構工具 (scale-building app, Shiny): `run_kitsui()` | [jiewenTsai/kitsUI](https://github.com/jiewenTsai/kitsUI) |
| **kitJoin** | KIT 資料處理工具 (data-processing app, Shiny): `run_kitjoin()` | [jiewenTsai/kitJoin](https://github.com/jiewenTsai/kitJoin) |
| **kitDesign** | The interface shared by both apps | [jiewenTsai/kitDesign](https://github.com/jiewenTsai/kitDesign) · [website](https://jiewentsai.github.io/kitDesign/) |

plus every package they need (about 90). RStudio is not needed.

## Install

### Windows: paste one line (it installs R too)

1. Press **Win+X** and choose **Terminal** (Windows 11) or **Windows PowerShell** (Windows 10).
2. Paste this line and press Enter:

   ```powershell
   irm https://raw.githubusercontent.com/jiewenTsai/kitverse/main/windows/install.ps1 | iex
   ```

3. Wait until it finishes (5–15 minutes the first time). If Windows asks to allow changes, choose Yes.
4. Shortcuts appear on the desktop, named in Chinese: one for kitsUI and one for kitJoin.
   Double-click one to start that app; no RStudio needed. A black window stays open while the app runs;
   closing it stops the app.
5. **Updating**: double-click the third shortcut ("KIT tools update", in Chinese) after closing the apps.
   It updates kitverse and every package to the newest version and remakes the shortcuts; press Enter to
   close it. The app shortcuts never update by themselves.

It finds R and installs the latest R from CRAN when there is none or it is older than CRAN's previous release (pre-built packages exist only for the current and previous release; the old R stays); runs
`install.R` below; and makes the desktop shortcuts (`kitverse::kitverse_shortcuts()`; run it again after
installing a new R). Running it twice does no harm.

### macOS, Linux, or R already installed

1. Install R: <https://cran.r-project.org> (the latest version for Windows or macOS).
2. Open R (Windows: "R" in the Start menu; macOS: "R" in Applications), paste this line and press Enter:

   ```r
   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
   ```

   The first time takes about 3–10 minutes. It ends with a checklist; all ✓ means you are ready.
   If there is a ✗, take a screenshot for the workshop assistants.

Windows and macOS need no Rtools or Xcode: every package comes pre-built. RStudio and Quarto are not
needed either: when R has no pandoc (needed to save plots), kitverse installs it.

<details>
<summary>Without source(): install by hand</summary>

```r
install.packages("kitverse", repos = c("https://jiewentsai.r-universe.dev",
                                       "https://cloud.r-project.org"))
kitverse::kitverse_update()   # update packages that are too old
kitverse::kitverse_check()    # check this computer
```

The first time a freshly installed R installs packages, it asks whether to use a "personal library":
answer Yes both times.
</details>

<details>
<summary>Ubuntu</summary>

The same line works (packages come pre-built from Posit Package Manager). If the checklist says a system
library is missing, run what it says, for example:

```bash
sudo apt install libuv1
```
</details>

## Use

```r
library(kitverse)   # attaches kits, kitsUI, kitJoin, kitDesign and lists their versions
run_kitsui()        # the scale-building app (from kitsUI)
run_kitjoin()       # the data-processing app (from kitJoin)
```

```
── Attaching core kitverse packages ─────────────────────────── kitverse 0.4.0 ──
✔ kits      0.25.2     ✔ kitJoin   0.7.0
✔ kitsUI    0.6.0      ✔ kitDesign 0.5.0
── Conflicts ─────────────────────────────────────────── kitverse_conflicts() ──
✖ kitJoin::kit_app() masks kitsUI::kit_app()
ℹ Start an app: run_kitsui() or run_kitjoin(). Check this computer: kitverse_check()
```

Like tidyverse, kitverse only installs and attaches the packages; their functions are used directly
(`run_kitsui()` comes from kitsUI, `run_kitjoin()` from kitJoin). kitverse itself only adds the
`kitverse_*()` helpers below.

The app opens in your browser. When you are done, go back to R and press Esc (the R window on macOS and
Windows) or Ctrl+C.

## When something goes wrong

| Situation | What to do |
|---|---|
| Not sure the computer is ready | `kitverse::kitverse_check()`: one line per item; at the end it really starts both apps |
| A package is "not installed" or "too old" | `kitverse::kitverse_update()`, then restart R |
| Update everything to the latest version | `kitverse::kitverse_update(all = TRUE)` |
| The checklist says a system library is missing (Linux) | Run the `sudo apt install …` it shows |

`library(kitverse)` itself never fails because another package is broken: it tells you to run
`kitverse_update()` instead.

## Before a workshop: everyone gets the same versions

The install line takes the KIT packages from r-universe, which rebuilds them after each push but can
lag behind (once its own deploy step failed and it stopped updating for two days). So there is also a
**KIT release**: one GitHub release of kitverse with the five KIT packages, listed in
`bundle/kit-bundle.dcf`. The install line, `kitverse_update()` and `kitverse_check()` compare r-universe
with it and take the KIT packages from the release whenever r-universe is behind. The KIT packages are
plain R, so this needs no Rtools; their other packages still come pre-built from CRAN.

1. **About a week before**: push the versions to ship, then in the kitverse folder
   `Rscript tools/release_bundle.R kit-2026.12.01` and push `bundle/kit-bundle.dcf`.
2. **Two days before**: `Rscript tools/check_versions.R`. One row per KIT package with the version on
   GitHub, r-universe, the release and this computer; every row should say `ok`.
3. **At the start**: everyone runs `kitverse::kitverse_check()`. The line "KIT release" says
   `current (kit-2026.12.01)` or lists what is behind; put the tag on a slide.

## Offline install at the workshop

Without internet, install from a repository on a USB drive:

```r
# the repository on the USB drive (both the KIT packages and the CRAN packages)
Sys.setenv(KITVERSE_REPO = "file:///D:/kitverse-repo", KITVERSE_CRAN = "file:///D:/kitverse-repo")
source("D:/kitverse-repo/install.R")
```

## For developers

- Loading the kitverse namespace loads no other package (NAMESPACE has no imports), so R CMD check gives
  one NOTE, "Namespaces in Imports field not imported from". This is on purpose: Imports only makes sure
  those packages get installed.
- Packages come from r-universe (<https://jiewentsai.r-universe.dev>): a CRAN-like repository with
  pre-built Windows and macOS packages that does not go through the GitHub API (with 80 people in one room,
  `remotes::install_github()` runs into GitHub's limit of 60 requests per hour).
- `Remotes:` must point at the same kitDesign tag as kitsUI and kitJoin (now `jiewenTsai/kitDesign@v0.8.0`);
  two different refs for one package make pak stop with "dependency conflict".
- R code must be ASCII: write symbols such as ✔ as `"\u2714"`.
