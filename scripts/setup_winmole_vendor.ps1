# Fetches WinMole, applies Khine patches, and syncs GUI adapters.
# Safe to run repeatedly - used by release_windows.ps1 and run_windows.ps1.
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$Dest = Join-Path $ProjectRoot "vendor\WinMole"
$KhineSource = Join-Path $ProjectRoot "scripts\windows\khine"

function Remove-VendorGit {
  param([string]$Target)

  $gitDir = Join-Path $Target ".git"
  if (Test-Path -LiteralPath $gitDir) {
    Remove-Item -LiteralPath $gitDir -Recurse -Force
    Write-Host "Removed nested .git from $Target"
  }

  $gitFile = Join-Path $Target ".git"
  if (Test-Path -LiteralPath $gitFile -PathType Leaf) {
    Remove-Item -LiteralPath $gitFile -Force
    Write-Host "Removed nested .git file from $Target"
  }
}

function Sync-KhineScripts {
  if (-not (Test-Path $KhineSource)) {
    return
  }
  if (-not (Test-Path (Join-Path $Dest "winmole.ps1"))) {
    return
  }

  $khineDest = Join-Path $Dest "bin\khine"
  New-Item -ItemType Directory -Force -Path $khineDest | Out-Null
  Copy-Item -Path (Join-Path $KhineSource "*.ps1") -Destination $khineDest -Force
  Write-Host "Synced Khine WinMole adapters to $khineDest"
}

function Apply-KhinePatches {
  $optimize = Join-Path $Dest "bin\optimize.ps1"
  if (Test-Path $optimize) {
    $content = Get-Content -LiteralPath $optimize -Raw
    if ($content -notmatch 'WINMOLE_NONINTERACTIVE') {
      $content = $content -replace `
        'if \(-not \$script:DryRun -and \(Test-IsAdmin\)\) \{', `
        "if (-not `$script:DryRun -and (Test-IsAdmin) -and `$env:WINMOLE_NONINTERACTIVE -ne '1') {"
      Set-Content -LiteralPath $optimize -Value $content -NoNewline
      Write-Host "Patched optimize.ps1 for Khine non-interactive mode"
    }
  }

  $clean = Join-Path $Dest "bin\clean.ps1"
  if (-not (Test-Path $clean)) {
    return
  }

  $cleanContent = Get-Content -LiteralPath $clean -Raw
  $patched = $false

  if ($cleanContent -match 'Clear-UserCaches') {
    $cleanContent = $cleanContent -replace `
      'if \(\$cleanUser\) \{\s*Clear-UserCaches\s*Clear-UserLogs\s*\}', `
      "if (`$cleanUser) {`n        Invoke-UserCleanup`n    }"
    $patched = $true
  }

  if ($cleanContent -match 'Clear-BrowserCaches|Clear-ApplicationCaches|Clear-WindowsUpdateCache') {
    $cleanContent = $cleanContent `
      -replace 'Clear-BrowserCaches', 'Clear-BrowserCacheFiles' `
      -replace 'Clear-ApplicationCaches', 'Clear-CommonAppCaches' `
      -replace 'Clear-WindowsUpdateCache', 'Clear-WindowsUpdateDownloads'
    $patched = $true
  }

  if ($cleanContent -match 'Invoke-DevCleanup') {
    $cleanContent = $cleanContent -replace 'Invoke-DevCleanup -All', 'Invoke-DevToolsCleanup'
    $patched = $true
  }

  if ($patched) {
    Set-Content -LiteralPath $clean -Value $cleanContent -NoNewline
    Write-Host "Patched clean.ps1 for Khine compatibility"
  }

  $fileOpsPatch = Join-Path $ProjectRoot "scripts\windows\patches\file_ops.ps1"
  $fileOpsDest = Join-Path $Dest "lib\core\file_ops.ps1"
  if ((Test-Path $fileOpsPatch) -and (Test-Path (Split-Path $fileOpsDest -Parent))) {
    Copy-Item -LiteralPath $fileOpsPatch -Destination $fileOpsDest -Force
    Write-Host "Applied Khine file_ops.ps1 patch"
  }
}

if (Test-Path (Join-Path $Dest "winmole.ps1")) {
  Remove-VendorGit -Target $Dest
  Sync-KhineScripts
  Apply-KhinePatches
  Write-Host "WinMole ready at $Dest"
  exit 0
}

Write-Host "Fetching WinMole from GitHub..."
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$tmp = "$Dest.tmp"
if (Test-Path $tmp) {
  Remove-Item -LiteralPath $tmp -Recurse -Force
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is required to fetch WinMole. Install Git for Windows and re-run."
}

git clone --depth 1 https://github.com/bhadraagada/winmole.git $tmp
if (-not (Test-Path (Join-Path $tmp "winmole.ps1"))) {
  throw "WinMole clone failed."
}

if (Test-Path $Dest) {
  Remove-Item -LiteralPath $Dest -Recurse -Force
}
Move-Item -LiteralPath $tmp -Destination $Dest

Remove-VendorGit -Target $Dest
Sync-KhineScripts
Apply-KhinePatches

Write-Host "WinMole ready at $Dest"
