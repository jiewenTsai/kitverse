# kitverse

English | [繁體中文](README.zh-TW.md)

Install the KIT research tools in one step and open them with one line. Installing kitverse installs:

- **kits**: item calibration, linking across cohorts, scoring.
- **kitsUI**: the scale-building app (Shiny).
- **kitJoin**: the data-joining app (Shiny).
- **kitDesign**: the interface shared by both apps.

plus every package they need (about 90). RStudio is not needed.

## Install

1. Install R: <https://cran.r-project.org> (the latest version for Windows or macOS).
2. Open R (Windows: "R" in the Start menu; macOS: "R" in Applications), paste this line and press Enter:

   ```r
   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
   ```

   The first time takes about 3–10 minutes. It ends with a checklist; all ✓ means you are ready.
   If there is a ✗, take a screenshot for the workshop assistants.

Windows and macOS need no Rtools or Xcode: every package comes pre-built.

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
kitverse::kitsui()    # open the scale-building app
kitverse::kitjoin()   # open the data-joining app
```

The app opens in your browser. When you are done, go back to R and press Esc (the R window on macOS and
Windows) or Ctrl+C.

You can also run `library(kitverse)` first: it loads the four packages, lists their versions, and then
`kitsui()` and `kitjoin()` work directly.

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
- `Remotes:` must point at the same kitDesign tag as kitsUI and kitJoin (now `jiewenTsai/kitDesign@v0.4.0`);
  two different refs for one package make pak stop with "dependency conflict".
- Chinese text in R strings must be written as `\uXXXX`: after editing, run
  `LC_ALL=en_US.UTF-8 Rscript tools/escape_non_ascii.R`.
