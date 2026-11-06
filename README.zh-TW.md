# kitverse

[English](README.md) | 繁體中文

一次裝好、一行打開 KIT 的研究工具。裝 kitverse 就會裝好：

| 套件 | 是什麼 | GitHub |
|---|---|---|
| **kits** | 題目校準、跨世代連結、計分 | [jiewenTsai/kits](https://github.com/jiewenTsai/kits) |
| **kitsUI** | KIT 量尺建構工具（Shiny app）：`run_kitsui()` | [jiewenTsai/kitsUI](https://github.com/jiewenTsai/kitsUI) |
| **kitJoin** | KIT 資料處理工具（Shiny app）：`run_kitjoin()` | [jiewenTsai/kitJoin](https://github.com/jiewenTsai/kitJoin) |
| **kitDesign** | 兩個 app 共用的介面 | [jiewenTsai/kitDesign](https://github.com/jiewenTsai/kitDesign) · [網站](https://jiewentsai.github.io/kitDesign/zh/) |

以及它們需要的所有套件（約 90 個）。不需要 RStudio。

## 安裝

### Windows：貼一行就好（連 R 都會裝）

1. 按 **Win+X**，選「**終端機**」（Windows 11）或「**Windows PowerShell**」（Windows 10）。
2. 貼上這一行，按 Enter：

   ```powershell
   irm https://raw.githubusercontent.com/jiewenTsai/kitverse/main/windows/install.ps1 | iex
   ```

3. 等它跑完（第一次約 5–15 分鐘）。如果 Windows 問「是否允許變更」，按「是」。
4. 桌面上會多兩個捷徑：「**KIT 量尺建構工具**」「**KIT 資料處理工具**」。雙擊就開啟，不需要 RStudio。
   使用時會有一個黑色視窗，app 開著時不要關它；關掉黑色視窗就會關閉 app。
5. **更新**：雙擊桌面的「**KIT 工具更新**」（先關掉 app 的黑色視窗）。它會把 kitverse 與所有套件更新到最新版、
   重建捷徑，最後按 Enter 關閉視窗。捷徑本身不會自動更新。R 太舊時（大約一年後），它會請你再貼一次上面那一行，
   裝新版的 R。

它會：找電腦上的 R，沒有，或比 CRAN 的前一版還舊（套件庫只替最新版和前一版編好套件），就從 CRAN 裝最新版（舊的 R 留著）；再執行下面的 `install.R`；最後建桌面捷徑
（`kitverse::kitverse_shortcuts()`，換了新版 R 之後可以再執行一次）。再跑一次沒有關係。

### macOS、Linux，或已經有 R

1. 裝 R：<https://cran.r-project.org>（Windows、macOS 都選最新版）。
2. 打開 R（Windows：開始選單的「R」；macOS：應用程式裡的「R」），貼上這一行，按 Enter：

   ```r
   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
   ```

   第一次約 3–10 分鐘。最後會印出一張檢查表，全部是 ✓ 就好了；有 ✗ 的話，請把畫面截圖給助教。

Windows 與 macOS 不用裝 Rtools 或 Xcode：所有套件都是編好的版本。也不用裝 RStudio 或 Quarto：
R 找不到 pandoc（存圖檔要用）時，kitverse 會自己裝。

<details>
<summary>不想用 source()：自己裝</summary>

```r
install.packages("kitverse", repos = c("https://jiewentsai.r-universe.dev",
                                       "https://cloud.r-project.org"))
kitverse::kitverse_update()   # 更新太舊的套件
kitverse::kitverse_check()    # 檢查這台電腦
```

剛裝好的 R 第一次安裝套件時，會問要不要用「個人的套件資料夾」（personal library）：兩次都回答「是／Yes」。
</details>

<details>
<summary>Ubuntu</summary>

同一行就可以（套件從 Posit Package Manager 拿編好的版本）。如果檢查表說缺少系統函式庫，照它寫的執行，例如：

```bash
sudo apt install libuv1
```
</details>

## 使用

```r
library(kitverse)   # 載入 kits、kitsUI、kitJoin、kitDesign，列出版本
run_kitsui()        # 量尺建構工具（kitsUI 的函式）
run_kitjoin()       # 資料處理工具（kitJoin 的函式）
```

```
── Attaching core kitverse packages ─────────────────────────── kitverse 0.4.0 ──
✔ kits      0.25.2     ✔ kitJoin   0.7.0
✔ kitsUI    0.6.0      ✔ kitDesign 0.5.0
── Conflicts ─────────────────────────────────────────── kitverse_conflicts() ──
✖ kitJoin::kit_app() masks kitsUI::kit_app()
ℹ Start an app: run_kitsui() or run_kitjoin(). Check this computer: kitverse_check()
```

和 tidyverse 一樣：kitverse 只負責裝好、載入這些套件，函式直接用各套件自己的
（`run_kitsui()` 是 kitsUI 的、`run_kitjoin()` 是 kitJoin 的）。kitverse 自己只多了下面這幾個 `kitverse_*()`。

瀏覽器會自動打開 app。用完回到 R 按 Esc（macOS、Windows 的 R 視窗）或 Ctrl+C 關掉。

## 出問題時

| 情況 | 怎麼做 |
|---|---|
| 不確定電腦能不能用 | `kitverse::kitverse_check()`：一項一行，最後會把兩個 app 真的開起來試 |
| 說有套件「沒有安裝」或「版本太舊」 | `kitverse::kitverse_update()`，再重新開 R |
| 想更新到最新版 | `kitverse::kitverse_update(all = TRUE)` |
| 檢查表說缺少系統函式庫（Linux） | 照它寫的 `sudo apt install …` |

`library(kitverse)` 本身不會因為別的套件壞掉而失敗：套件有問題時它會說要執行 `kitverse_update()`。

## 工作坊前：確保每個人都是同樣的版本

安裝指令從 r-universe 拿 KIT 的套件。r-universe 在每次推上 GitHub 後會重建，但可能落後（曾經它自己的發布步驟出錯，兩天沒有更新）。所以另外有一個 **KIT release**：kitverse 的一個 GitHub release，放五個 KIT 套件，清單在 `bundle/kit-bundle.dcf`。安裝指令、`kitverse_update()` 與 `kitverse_check()` 會拿 r-universe 和它比；r-universe 落後時，KIT 的套件改從 release 裝。KIT 的套件都是純 R，不需要 Rtools；它們用到的其他套件照樣從 CRAN 裝預先建好的版本。

1. **大約一週前**：把要用的版本推上 GitHub，在 kitverse 資料夾執行 `Rscript tools/release_bundle.R kit-2026.12.01`，再推 `bundle/kit-bundle.dcf`。
2. **兩天前**：執行 `Rscript tools/check_versions.R`。每個 KIT 套件一列，列出 GitHub、r-universe、release 與這台電腦的版本；每一列都要是 `ok`。
3. **現場一開始**：每個人跑 `kitverse::kitverse_check()`。「KIT release」那一行會寫 `current (kit-2026.12.01)`，或列出哪些落後；投影片上放這個標籤。

## 工作坊現場的離線安裝

沒有網路時，從 USB 的套件庫安裝：

```r
# USB 上的套件庫（KIT 的套件與 CRAN 的套件都在裡面）
Sys.setenv(KITVERSE_REPO = "file:///D:/kitverse-repo", KITVERSE_CRAN = "file:///D:/kitverse-repo")
source("D:/kitverse-repo/install.R")
```

## 給開發者

- 載入 kitverse 的 namespace 不會載入任何其他套件（NAMESPACE 沒有 import），所以 R CMD check
  會有一個 NOTE「Namespaces in Imports field not imported from」：這是故意的。Imports 只是讓這些套件被裝好。
- 套件從 r-universe（<https://jiewentsai.r-universe.dev>）裝：像 CRAN 一樣的套件庫，有 Windows、macOS 編好的
  版本，而且不經過 GitHub API（80 人在同一個會場用 `remotes::install_github()` 時，GitHub 每小時 60 次的限制會被用完）。
- `Remotes:` 的 kitDesign 要和 kitsUI、kitJoin 指向同一個 tag（現在是 `jiewenTsai/kitDesign@v0.8.0`）：
  同一個套件有兩個不同的來源時，pak 會停在「dependency conflict」。
- R 程式碼只能用 ASCII：✔ 這類符號要寫成 `"\u2714"`。
