# Builds Khine Windows release artifacts:
#   - Khine-<version>-windows-setup.exe  (recommended installer)
#   - Khine-<version>-windows.zip        (portable)
# Run on Windows 10/11 with Flutter + Visual Studio C++ tools installed.
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [switch]$SkipInstaller
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

$AppName = "Khine"
$VersionLine = Select-String -Path (Join-Path $ProjectRoot "pubspec.yaml") -Pattern '^version:\s*(.+)$'
if (-not $VersionLine) {
  throw "Could not read version from pubspec.yaml"
}
$Version = ($VersionLine.Matches.Groups[1].Value.Trim() -split '\+')[0]

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

  $khineSource = Join-Path $ProjectRoot "scripts\windows\khine"
  if (Test-Path $khineSource) {
    $khineDest = Join-Path $vendor "bin\khine"
    New-Item -ItemType Directory -Force -Path $khineDest | Out-Null
    Copy-Item -Path (Join-Path $khineSource "*.ps1") -Destination $khineDest -Force
  }
}

function Remove-StaleBuildPath {
  $buildPath = Join-Path $ProjectRoot "build"
  if (-not (Test-Path -LiteralPath $buildPath)) {
    return
  }

  $item = Get-Item -LiteralPath $buildPath -Force
  if ($item.LinkType -or -not $item.PSIsContainer) {
    Write-Host "Removing stale build symlink/file..."
    Remove-Item -LiteralPath $buildPath -Force -Recurse
  }
}

function Find-InnoSetupCompiler {
  $candidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  $where = Get-Command ISCC.exe -ErrorAction SilentlyContinue
  if ($where) {
    return $where.Source
  }

  return $null
}

function Build-WindowsInstaller {
  param(
    [string]$SourceDir,
    [string]$DistDir,
    [string]$AppVersion
  )

  $iss = Join-Path $ProjectRoot "scripts\windows\khine.iss"
  if (-not (Test-Path $iss)) {
    throw "Installer script not found: $iss"
  }

  $iscc = Find-InnoSetupCompiler
  if (-not $iscc) {
    Write-Warning "Inno Setup was not found. Skipping setup.exe build."
    Write-Warning "Install Inno Setup 6, then re-run this script to create the installer."
    return $null
  }

  $iconFile = Join-Path $ProjectRoot "windows\runner\resources\app_icon.ico"
  if (-not (Test-Path $iconFile)) {
    $iconFile = Join-Path $SourceDir "$AppName.exe"
  }

  Write-Host "Building Windows installer..."
  & $iscc `
    "/DMyAppVersion=$AppVersion" `
    "/DSourceDir=$SourceDir" `
    "/DOutputDir=$DistDir" `
    "/DIconFile=$iconFile" `
    $iss

  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compiler failed with exit code $LASTEXITCODE"
  }

  $setupPath = Join-Path $DistDir "$AppName-$AppVersion-windows-setup.exe"
  if (-not (Test-Path $setupPath)) {
    throw "Installer was not created at: $setupPath"
  }

  return $setupPath
}

Write-Host "Preparing release $AppName $Version..."
Remove-StaleBuildPath
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

$SetupPath = $null
if (-not $SkipInstaller) {
  $SetupPath = Build-WindowsInstaller -SourceDir $ReleaseDir -DistDir $DistDir -AppVersion $Version
}

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
if ($SetupPath) {
  Write-Host "  Installer:  $SetupPath"
}
Write-Host "  Zip:        $ZipPath"
Write-Host ""
if ($SetupPath) {
  Write-Host "Share the setup.exe with other Windows users."
  Write-Host "Double-click it to install Khine to Program Files."
}
else {
  Write-Host "Share the zip with other Windows users."
  Write-Host "They should extract it and run $AppName.exe."
}
Write-Host "Bundled WinMole is included - no separate install required."
