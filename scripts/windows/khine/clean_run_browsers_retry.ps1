# Khine adapter: retry browser cache cleanup after the user closes their browser.
#Requires -Version 5.1

. "$PSScriptRoot\_common.ps1"

if (-not $env:WINMOLE_NONINTERACTIVE) {
    $env:WINMOLE_NONINTERACTIVE = '1'
}

$cleanScript = Join-Path $script:WINMOLE_ROOT 'bin\clean.ps1'
if (-not (Test-Path -LiteralPath $cleanScript)) {
    Write-WinMoleError "WinMole clean script not found: $cleanScript"
    exit 1
}

Write-Info 'Retrying browser cache cleanup...'
& $cleanScript -Browsers
exit $LASTEXITCODE
