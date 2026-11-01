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
- `Remotes:` 的 kitDesign 要和 kitsUI、kitJoin 指向同一個 tag（現在是 `jiewenTsai/kitDesign@v0.7.1`）：
  同一個套件有兩個不同的來源時，pak 會停在「dependency conflict」。
- R 程式碼只能用 ASCII：✔ 這類符號要寫成 `"\u2714"`。
