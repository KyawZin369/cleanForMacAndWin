# Builds Khine Windows release artifacts (one command - no manual setup):
#   - Khine-<version>-windows-setup.exe  (recommended installer)
#   - Khine-<version>-windows.zip        (portable)
#
# Prerequisites (install once on the build machine):
#   - Flutter SDK (Windows desktop)
#   - Visual Studio 2022 with Desktop development with C++
#   - Git for Windows
#   - Python 3 (optional, for icon generation)
#   - Inno Setup 6 (optional; auto-installed via Chocolatey when available)
#
# End users only need to run the setup.exe or extract the zip - WinMole is bundled.
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

function Ensure-InnoSetupCompiler {
  $iscc = Find-InnoSetupCompiler
  if ($iscc) {
    return $iscc
  }

  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Inno Setup not found. Installing via Chocolatey..."
    & choco install innosetup -y --no-progress
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Chocolatey Inno Setup install failed."
      return $null
    }
    return Find-InnoSetupCompiler
  }

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Inno Setup not found. Installing via winget..."
    & winget install --id JRSoftware.InnoSetup -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "winget Inno Setup install failed."
      return $null
    }
    return Find-InnoSetupCompiler
  }

  return $null
}

function Find-SignTool {
  $candidates = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64\signtool.exe",
    "${env:ProgramFiles(x86)}\Windows Kits\10\App Certification Kit\signtool.exe"
  )
  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { return $candidate }
  }
  $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Sign-FileIfConfigured {
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path $Path)) { return $false }

  $pfxPath = $env:KHINE_SIGN_PFX_PATH
  $pfxPassword = $env:KHINE_SIGN_PFX_PASSWORD
  $thumbprint = $env:KHINE_SIGN_CERT_SHA1
  $timestampUrl = if ($env:KHINE_SIGN_TIMESTAMP_URL) {
    $env:KHINE_SIGN_TIMESTAMP_URL
  } else {
    "http://timestamp.digicert.com"
  }

  if (-not $pfxPath -and -not $thumbprint) {
    return $false
  }

  $signTool = Find-SignTool
  if (-not $signTool) {
    Write-Warning "Signing requested but signtool.exe was not found. Skipping signing."
    return $false
  }

  Write-Host "Signing $Path ..."
  $args = @("sign", "/fd", "SHA256", "/tr", $timestampUrl, "/td", "SHA256")
  if ($pfxPath) {
    $args += @("/f", $pfxPath)
    if ($pfxPassword) { $args += @("/p", $pfxPassword) }
  } elseif ($thumbprint) {
    $args += @("/sha1", $thumbprint)
  }
  $args += $Path

  & $signTool @args
  if ($LASTEXITCODE -ne 0) {
    throw "Code signing failed for $Path (exit $LASTEXITCODE)"
  }
  return $true
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

  $iscc = Ensure-InnoSetupCompiler
  if (-not $iscc) {
    Write-Warning "Inno Setup was not found. Skipping setup.exe build."
    Write-Warning "Install Inno Setup 6, or install Chocolatey/winget and re-run this script."
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

function Test-ReleaseBundle {
  param([string]$ReleaseDir)

  $required = @(
    (Join-Path $ReleaseDir "$AppName.exe"),
    (Join-Path $ReleaseDir "winmole\winmole.ps1"),
    (Join-Path $ReleaseDir "winmole\bin\clean.ps1"),
    (Join-Path $ReleaseDir "winmole\bin\optimize.ps1"),
    (Join-Path $ReleaseDir "winmole\bin\analyze.exe"),
    (Join-Path $ReleaseDir "winmole\bin\status.exe"),
    (Join-Path $ReleaseDir "winmole\bin\khine\clean_run.ps1"),
    (Join-Path $ReleaseDir "winmole\bin\khine\analyze_json.ps1"),
    (Join-Path $ReleaseDir "winmole\bin\khine\status_json.ps1"),
    (Join-Path $ReleaseDir "winmole\bin\khine\uninstall_list.ps1"),
    (Join-Path $ReleaseDir "INSTALL.txt")
  )

  $missing = @()
  foreach ($path in $required) {
    if (-not (Test-Path $path)) {
      $missing += $path
    }
  }

  if ($missing.Count -gt 0) {
    throw ("Release bundle verification failed. Missing:`n  " + ($missing -join "`n  "))
  }

  Write-Host "Release bundle verification passed."
}

Write-Host "Preparing release $AppName $Version..."
Write-Host "This script fetches WinMole, builds Khine, and packages everything."
Write-Host "No manual vendor setup or environment variables are required."
Write-Host ""

Remove-StaleBuildPath
& (Join-Path $ProjectRoot "scripts\setup_winmole_vendor.ps1") -ProjectRoot $ProjectRoot

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

Copy-Item `
  (Join-Path $ProjectRoot "scripts\windows\INSTALL.txt") `
  (Join-Path $ReleaseDir "INSTALL.txt") `
  -Force

Test-ReleaseBundle -ReleaseDir $ReleaseDir

$signedApp = Sign-FileIfConfigured -Path $ExePath

$DistDir = Join-Path $ProjectRoot "dist\windows"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$SetupPath = $null
if (-not $SkipInstaller) {
  $SetupPath = Build-WindowsInstaller -SourceDir $ReleaseDir -DistDir $DistDir -AppVersion $Version
  if ($SetupPath) {
    [void](Sign-FileIfConfigured -Path $SetupPath)
  }
}

$StageRoot = Join-Path $env:TEMP ("khine-win-{0}" -f [guid]::NewGuid().ToString("N"))
$StageApp = Join-Path $StageRoot $AppName
New-Item -ItemType Directory -Force -Path $StageApp | Out-Null

Write-Host "Staging portable app folder..."
robocopy $ReleaseDir $StageApp /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
  throw "Failed to copy release files (robocopy exit $LASTEXITCODE)."
}

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
Write-Host "Share with other Windows users - they do not need Flutter, Git, or WinMole."
if ($SetupPath) {
  Write-Host "  Recommended: double-click $AppName-$Version-windows-setup.exe"
}
else {
  Write-Host "  Portable: extract $ZipName and run $AppName.exe"
}
Write-Host "WinMole is bundled inside the app. No separate install required."
if (-not $signedApp) {
  Write-Warning "This build is unsigned. Windows SmartScreen may show 'Windows protected your PC'."
  Write-Warning "To remove trust warnings, sign releases with a trusted code-signing certificate."
}
