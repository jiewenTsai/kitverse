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
- `Remotes:` must point at the same kitDesign tag as kitsUI and kitJoin (now `jiewenTsai/kitDesign@v0.5.2`);
  two different refs for one package make pak stop with "dependency conflict".
- R code must be ASCII: write symbols such as ✔ as `"\u2714"`.
