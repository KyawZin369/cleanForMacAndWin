# Khine adapter: administrator-only cleanup (UAC elevation).
#Requires -Version 5.1

param(
    [switch]$KhineElevatedChild,
    [string]$KhineLogFile
)

. "$PSScriptRoot\_common.ps1"

if (-not $env:WINMOLE_NONINTERACTIVE) {
    $env:WINMOLE_NONINTERACTIVE = '1'
}

if (-not (Test-IsAdmin) -and -not $KhineElevatedChild) {
    exit (Invoke-KhineElevatedScript -ScriptPath $PSCommandPath)
}

if ($KhineLogFile) {
    Start-KhineScriptLogging -LogFile $KhineLogFile
}

try {
    $cleanScript = Join-Path $script:WINMOLE_ROOT 'bin\clean.ps1'
    if (-not (Test-Path -LiteralPath $cleanScript)) {
        Write-WinMoleError "WinMole clean script not found: $cleanScript"
        exit 1
    }

    Write-Info 'Running protected system cleanup as administrator...'
    & $cleanScript -System -WindowsUpdate -RecycleBin
    $systemExit = $LASTEXITCODE

    Write-Info 'Running administrator cache cleanup...'
    & $cleanScript -Caches
    $cacheExit = $LASTEXITCODE

    if ($systemExit -ne 0 -or $cacheExit -ne 0) {
        exit 1
    }
}
finally {
    if ($KhineLogFile) {
        Stop-KhineScriptLogging
    }
}

exit 0