# Run Khine on Windows in development mode with bundled WinMole.
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

& (Join-Path $PSScriptRoot "setup_winmole_vendor.sh")

$env:WINMOLE_VENDOR_ROOT = Join-Path $ProjectRoot "vendor\WinMole"
$env:MOLE_VENDOR_ROOT = $env:WINMOLE_VENDOR_ROOT

flutter pub get
flutter run -d windows @args
