# Shared helpers for Khine GUI WinMole adapters.
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $script:WINMOLE_ROOT) {
    $script:WINMOLE_ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$script:WINMOLE_LIB = Join-Path $script:WINMOLE_ROOT 'lib'

if (Test-Path (Join-Path $script:WINMOLE_LIB 'core\common.ps1')) {
    . (Join-Path $script:WINMOLE_LIB 'core\common.ps1')
    Initialize-WinMole | Out-Null
}

function Write-KhineJson {
    param([Parameter(Mandatory)][object]$Payload)
    $json = $Payload | ConvertTo-Json -Depth 8 -Compress
    [Console]::Out.WriteLine($json)
}

function Format-HumanSize {
    param([long]$Bytes)
    if ($Bytes -ge 1TB) { return '{0:N2}TB' -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return '{0:N2}GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N2}MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N2}KB' -f ($Bytes / 1KB) }
    return '{0}B' -f $Bytes
}

function Get-DirectorySizeBytes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    try {
        $items = Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue
        return ($items | Measure-Object -Property Length -Sum).Sum
    }
    catch {
        return 0
    }
}
