# Khine adapter: retry cleanup for files that were locked during the first pass.
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

Write-Info 'Retrying cleanup for temp files and GPU shader caches...'
& $cleanScript -User -GPUShaders
exit $LASTEXITCODE
