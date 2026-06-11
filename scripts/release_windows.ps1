# Builds a portable Khine Windows release zip for other PCs.
# Run on Windows 10/11 with Flutter + Visual Studio C++ tools installed.
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

$AppName = "Khine"
$VersionLine = Select-String -Path (Join-Path $ProjectRoot "pubspec.yaml") -Pattern '^version:\s*(.+)$'
if (-not $VersionLine) {
  throw "Could not read version from pubspec.yaml"
}
$Version = $VersionLine.Matches.Groups[1].Value.Trim()

function Ensure-WinMoleVendor {
  $vendor = Join-Path $ProjectRoot "vendor\WinMole"
  $script = Join-Path $vendor "winmole.ps1"
  if (Test-Path $script) {
    return
  }

  Write-Host "Fetching WinMole vendor..."
  New-Item -ItemType Directory -Force -Path $vendor | Out-Null
  git clone --depth 1 https://github.com/bhadraagada/winmole.git $vendor
  if (-not (Test-Path $script)) {
    throw "WinMole vendor setup failed."
  }
}

Write-Host "Preparing release $AppName $Version..."
Ensure-WinMoleVendor

if (Get-Command python -ErrorAction SilentlyContinue) {
  python (Join-Path $ProjectRoot "scripts\generate_app_icons.py")
  python (Join-Path $ProjectRoot "scripts\generate_windows_icons.py")
}

flutter pub get
Write-Host "Building Windows release..."
flutter build windows --release

$ReleaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$ExePath = Join-Path $ReleaseDir "$AppName.exe"
if (-not (Test-Path $ExePath)) {
  throw "Release executable not found at: $ExePath"
}

& (Join-Path $ProjectRoot "scripts\bundle_winmole.ps1") -OutputDir (Join-Path $ReleaseDir "winmole")

$WinMoleScript = Join-Path $ReleaseDir "winmole\winmole.ps1"
if (-not (Test-Path $WinMoleScript)) {
  throw "Bundled WinMole not found at: $WinMoleScript"
}

$DistDir = Join-Path $ProjectRoot "dist\windows"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$StageRoot = Join-Path $env:TEMP ("khine-win-{0}" -f [guid]::NewGuid().ToString("N"))
$StageApp = Join-Path $StageRoot $AppName
New-Item -ItemType Directory -Force -Path $StageApp | Out-Null

Write-Host "Staging portable app folder..."
robocopy $ReleaseDir $StageApp /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
  throw "Failed to copy release files (robocopy exit $LASTEXITCODE)."
}

Copy-Item (Join-Path $ProjectRoot "scripts\windows\INSTALL.txt") (Join-Path $StageApp "INSTALL.txt") -Force

$ZipName = "$AppName-$Version-windows.zip"
$ZipPath = Join-Path $DistDir $ZipName
if (Test-Path $ZipPath) {
  Remove-Item $ZipPath -Force
}

Write-Host "Creating zip..."
Compress-Archive -Path $StageApp -DestinationPath $ZipPath -Force
Remove-Item $StageRoot -Recurse -Force

Write-Host ""
Write-Host "Release build complete."
Write-Host "  App folder: $ReleaseDir"
Write-Host "  Zip:        $ZipPath"
Write-Host ""
Write-Host "Share the zip with other Windows users."
Write-Host "They should extract it and run $AppName.exe."
Write-Host "Bundled WinMole is included - no separate install required."
