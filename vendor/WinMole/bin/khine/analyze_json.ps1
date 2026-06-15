# Khine adapter: disk analyze JSON for the Flutter UI.
#Requires -Version 5.1
param(
    [string]$Path
)

. "$PSScriptRoot\_common.ps1"

$target = if ($Path) { $Path } else { $env:USERPROFILE }
if (-not (Test-Path -LiteralPath $target)) {
    Write-Error "Path does not exist: $target"
    exit 1
}

$resolved = (Resolve-Path -LiteralPath $target).Path
$entries = @()
$totalSize = 0L

Get-ChildItem -LiteralPath $resolved -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        $size = if ($_.PSIsContainer) {
            Get-DirectorySizeBytes -Path $_.FullName
        }
        else {
            [long]$_.Length
        }
        $totalSize += $size
        $entries += [PSCustomObject]@{
            name      = $_.Name
            path      = $_.FullName
            size      = $size
            is_dir    = $_.PSIsContainer
            insight   = $false
            cleanable = ($_.Name -in @(
                'node_modules', 'vendor', '.venv', 'venv', '__pycache__',
                'target', 'build', 'dist', '.next', '.nuxt', 'bin', 'obj'
            ))
        }
    }

$entries = @($entries | Sort-Object size -Descending)

Write-KhineJson -Payload ([ordered]@{
    path        = $resolved
    overview    = $false
    entries     = $entries
    total_size  = $totalSize
    total_files = ($entries | Where-Object { -not $_.is_dir }).Count
})
