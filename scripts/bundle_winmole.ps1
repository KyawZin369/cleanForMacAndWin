# Copies WinMole into the Flutter Windows build output.
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutputDir = ""
)

$vendor = Join-Path $ProjectRoot "vendor\WinMole"
if (-not (Test-Path (Join-Path $vendor "winmole.ps1"))) {
  Write-Error "WinMole vendor missing. Run: sh scripts/setup_winmole_vendor.sh"
  exit 1
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release\winmole"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
robocopy $vendor $OutputDir /E /XD .git tests /XF ._* /NFL /NDL /NJH /NJS /NP | Out-Null

$khineSource = Join-Path $ProjectRoot "scripts\windows\khine"
if (Test-Path $khineSource) {
  $khineDest = Join-Path $OutputDir "bin\khine"
  New-Item -ItemType Directory -Force -Path $khineDest | Out-Null
  robocopy $khineSource $khineDest *.ps1 /NFL /NDL /NJH /NJS /NP | Out-Null
}
if ($LASTEXITCODE -ge 8) {
  Write-Error "robocopy failed with exit code $LASTEXITCODE"
  exit 1
}
Write-Host "Bundled WinMole to $OutputDir"
