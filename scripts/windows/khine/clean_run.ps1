# Khine adapter: non-interactive full clean for the GUI.
#Requires -Version 5.1

. "$PSScriptRoot\_common.ps1"

$cleanScript = Join-Path $script:WINMOLE_ROOT 'bin\clean.ps1'
if (-not (Test-Path -LiteralPath $cleanScript)) {
    Write-Error "WinMole clean script not found: $cleanScript"
    exit 1
}

& $cleanScript -All
exit $LASTEXITCODE
