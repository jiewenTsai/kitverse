# KIT 研究工具：Windows 一鍵安裝
#
# 學員在「終端機」或「Windows PowerShell」（按 Win+X 打開）貼上這一行，按 Enter：
#
#   irm https://raw.githubusercontent.com/jiewenTsai/kitverse/main/windows/install.ps1 | iex
#
# 它做三件事：
# 1. 找電腦上的 R；沒有，或比 CRAN 的前一版還舊（套件庫不再替它編好套件），就從 CRAN 下載
#    最新版 R 的官方安裝檔，靜默安裝（舊的 R 留著不刪），桌面捷徑會改用新的 R
#    （如果 Windows 問「是否允許變更」，按「是」）；
# 2. 用這個 R 執行 kitverse 的 install.R：裝 kitverse 與它需要的套件（r-universe 已編譯好的版本，
#    不用 Rtools）、裝 pandoc、檢查這台電腦（真的開一次兩個 app）；
# 3. install.R 最後在桌面建捷徑（kitverse_shortcuts()）：兩個 app 各一個，雙擊就開，不需要 RStudio；
#    另一個「KIT 工具更新」雙擊就把套件更新到最新版。
#
# 再跑一次沒有關係：R 夠新就不會重裝，套件夠新就不會重抓。
#
# 環境變數（測試、離線用）：
#   KITVERSE_INSTALL_R=1     不管有沒有 R，都安裝最新版
#   KITVERSE_INSTALL_URL=…   install.R 的位置（網址或本機路徑）
#   KITVERSE_REPO、KITVERSE_CRAN  套件庫的位置，install.R 會讀（見 install.R）

& {
  $ErrorActionPreference = 'Continue'
  $ProgressPreference = 'SilentlyContinue'   # Windows PowerShell 的下載進度條會讓下載慢很多
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $cran = 'https://cloud.r-project.org/bin/windows/base'
  $installR = if ($env:KITVERSE_INSTALL_URL) { $env:KITVERSE_INSTALL_URL } else {
    'https://raw.githubusercontent.com/jiewenTsai/kitverse/main/install.R'
  }

  function Say($text, $color = 'White') { Write-Host $text -ForegroundColor $color }
  function Fail($text) {
    Say ''
    Say "✖ $text" 'Red'
    Say '  請把這個視窗的畫面截圖給工作坊助教。' 'Red'
  }

  # R 安裝在哪裡：先看登錄檔（R 安裝程式寫的「目前版本」），再看常見的資料夾
  function Find-Rscript {
    $dirs = @()
    foreach ($hive in 'HKCU:', 'HKLM:') {
      $key = "$hive\SOFTWARE\R-core\R"
      if (Test-Path $key) {
        $p = (Get-ItemProperty $key -ErrorAction SilentlyContinue).InstallPath
        if ($p) { $dirs += $p }
      }
    }
    foreach ($root in "$env:ProgramFiles\R", "$env:LOCALAPPDATA\Programs\R") {
      if (Test-Path $root) {
        # 只看 R-4.5.3 這種資料夾（同一層可能有 bin 之類的別的資料夾），新的版本先
        $dirs += Get-ChildItem $root -Directory |
          Where-Object { $_.Name -match '^R-\d+\.\d+(\.\d+)?$' } |
          Sort-Object { [version]($_.Name -replace '^R-', '') } -Descending |
          ForEach-Object { $_.FullName }
      }
    }
    foreach ($d in $dirs) {
      $exe = Join-Path $d 'bin\Rscript.exe'
      if (Test-Path $exe) { return $exe }
    }
    return $null
  }

  # 最舊可以用的 R：CRAN 的前一版（Old-release）的 x.y。r-universe 與 CRAN 只替最新版和前一版
  # 編好 Windows 的套件；更舊的 R 更新套件時要編譯（要 Rtools），學員的電腦沒有。連不上 CRAN 時用 4.2。
  function Get-MinimumR {
    try {
      $info = (Invoke-WebRequest 'https://cloud.r-project.org/src/base/VERSION-INFO.dcf' -UseBasicParsing -TimeoutSec 20).Content
      if ($info -match 'Old-release:\s*(\d+)\.(\d+)') { return "$($Matches[1]).$($Matches[2]).0" }
    } catch {}
    return '4.2.0'
  }

  function Get-RVersion($rscript) {
    return (& $rscript -e "cat(as.character(getRversion()))" 2>$null)
  }

  function Test-RNewEnough($rscript, $minimum) {
    $out = & $rscript -e "cat(getRversion() >= '$minimum' && getRversion() >= '4.2.0')" 2>$null
    return ($out -eq 'TRUE')
  }

  function Install-R {
    Say '== 安裝 R（約 2-5 分鐘；如果 Windows 問「是否允許變更」，請按「是」）' 'Cyan'
    $page = (Invoke-WebRequest "$cran/release.html" -UseBasicParsing).Content
    if ($page -notmatch 'URL=(R-[0-9.]+-win\.exe)') { throw '在 CRAN 找不到 R 的安裝檔' }
    $file = $Matches[1]
    $exe = Join-Path $env:TEMP $file
    Say "   下載 $file"
    Invoke-WebRequest "$cran/$file" -OutFile $exe -UseBasicParsing
    Say '   安裝中…'
    $p = Start-Process $exe -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-' -Wait -PassThru
    Remove-Item $exe -ErrorAction SilentlyContinue
    if ($p.ExitCode -ne 0) { throw "R 的安裝程式沒有完成（代碼 $($p.ExitCode)）" }
  }

  Say ''
  Say '=== KIT 研究工具：安裝 ===' 'Cyan'

  # 1. R：沒有，或比 CRAN 的前一版舊，就裝最新版（舊的 R 留著，不刪）
  $minimum = Get-MinimumR
  $rscript = Find-Rscript
  if ($rscript -and -not $env:KITVERSE_INSTALL_R -and (Test-RNewEnough $rscript $minimum)) {
    Say "✔ 已經有 R $(Get-RVersion $rscript)：$rscript" 'Green'
  } else {
    if ($rscript -and -not $env:KITVERSE_INSTALL_R) {
      Say "  這台電腦的 R（$(Get-RVersion $rscript)）太舊了：KIT 的套件需要 $minimum 以上。" 'Yellow'
      Say '  會另外裝最新版的 R；舊的 R 不會刪除，你其他的 R 程式照樣可以用。' 'Yellow'
    } elseif (-not $rscript) {
      Say '  這台電腦還沒有 R，現在幫你裝。' 'Yellow'
    }
    try { Install-R } catch { Fail "安裝 R 失敗：$($_.Exception.Message)"; return }
    $rscript = Find-Rscript
    if (-not $rscript -or -not (Test-RNewEnough $rscript $minimum)) { Fail 'R 裝好了，但找不到可以用的 Rscript.exe'; return }
    Say "✔ R $(Get-RVersion $rscript) 已安裝：$rscript" 'Green'
  }

  # 2. 套件、pandoc、檢查、桌面捷徑（install.R）
  Say ''
  Say '== 安裝 KIT 的套件（第一次約 3-10 分鐘，請不要關掉這個視窗）' 'Cyan'
  $src = $installR -replace '\\', '/'
  & $rscript -e "source('$src')"
  if ($LASTEXITCODE -ne 0) { Fail '安裝套件時出了問題（看上面的紅字）'; return }

  Say ''
  Say '=== 完成 ===' 'Green'
  Say '桌面上有兩個捷徑：「KIT 量尺建構工具」「KIT 資料處理工具」。雙擊就會開啟。' 'Green'
  Say '要更新時，雙擊桌面的「KIT 工具更新」（先關掉 app 的黑色視窗）。' 'Green'
  Say '使用時會有一個黑色視窗，app 開著時不要關它；關掉黑色視窗就會關閉 app。' 'Green'
}
