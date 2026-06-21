# Shared helpers for Khine GUI WinMole adapters.
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedRoot = $null
if (Get-Variable -Name WINMOLE_ROOT -Scope Script -ErrorAction SilentlyContinue) {
    $resolvedRoot = $script:WINMOLE_ROOT
}
if (-not $resolvedRoot) {
    if ($env:WINMOLE_ROOT) {
        $resolvedRoot = $env:WINMOLE_ROOT.TrimEnd('\')
    }
    elseif ($env:WINMOLE_VENDOR_ROOT) {
        $resolvedRoot = $env:WINMOLE_VENDOR_ROOT.TrimEnd('\')
    }
    else {
        $resolvedRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    }
}
$script:WINMOLE_ROOT = $resolvedRoot

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

function Invoke-KhineElevatedScript {
    <#
    .SYNOPSIS
        Re-runs a Khine adapter script with UAC elevation and replays its log output.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [string[]]$ScriptArguments = @()
    )

    if (Test-IsAdmin) {
        & $ScriptPath @ScriptArguments
        return $LASTEXITCODE
    }

    $logFile = Join-Path $env:TEMP ("khine-elev-{0}.log" -f [Guid]::NewGuid().ToString('n'))
    $argList = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $ScriptPath,
        '-KhineElevatedChild',
        '-KhineLogFile', $logFile
    ) + $ScriptArguments

    Write-Info 'Requesting administrator approval (UAC)...'
    $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait -PassThru
    if (Test-Path -LiteralPath $logFile) {
        Get-Content -LiteralPath $logFile -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_ }
        Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
    }

    if ($null -eq $proc) {
        Write-WinMoleWarning 'Administrator approval was cancelled.'
        return 1
    }

    return [int]$proc.ExitCode
}

function Start-KhineScriptLogging {
    param([string]$LogFile)

    if ([string]::IsNullOrWhiteSpace($LogFile)) {
        return
    }

    $logDir = Split-Path -Parent $LogFile
    if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    }

    Start-Transcript -LiteralPath $LogFile -Force | Out-Null
}

function Stop-KhineScriptLogging {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
        # Transcript may not have started.
    }
}
