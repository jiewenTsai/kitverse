# kitverse

[English](README.md) | 繁體中文

一次裝好、一行打開 KIT 的研究工具。裝 kitverse 就會裝好：

- **kits**：題目校準、跨世代連結、計分。
- **kitsUI**：量尺建構工具（Shiny app）。
- **kitJoin**：資料串接工具（Shiny app）。
- **kitDesign**：兩個 app 共用的介面。

以及它們需要的所有套件（約 90 個）。不需要 RStudio。

## 安裝

1. 裝 R：<https://cran.r-project.org>（Windows、macOS 都選最新版）。
2. 打開 R（Windows：開始選單的「R」；macOS：應用程式裡的「R」），貼上這一行，按 Enter：

   ```r
   source("https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R")
   ```

   第一次約 3–10 分鐘。最後會印出一張檢查表，全部是 ✓ 就好了；有 ✗ 的話，請把畫面截圖給助教。

Windows 與 macOS 不用裝 Rtools 或 Xcode：所有套件都是編好的版本。

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
kitverse::kitsui()    # 開量尺建構工具
kitverse::kitjoin()   # 開資料串接工具
```

瀏覽器會自動打開 app。用完回到 R 按 Esc（macOS、Windows 的 R 視窗）或 Ctrl+C 關掉。

也可以先 `library(kitverse)`：會載入四個套件、列出版本，之後直接打 `kitsui()`、`kitjoin()`。

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
- R 程式碼裡的中文字串要換成 `\uXXXX`：寫完跑 `LC_ALL=en_US.UTF-8 Rscript tools/escape_non_ascii.R`。
