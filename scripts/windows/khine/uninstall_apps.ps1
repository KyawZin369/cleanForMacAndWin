# Khine adapter: headless uninstall for selected app names.
#Requires -Version 5.1
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AppNames
)

. "$PSScriptRoot\uninstall_lib.ps1"

if (-not $AppNames -or $AppNames.Count -eq 0) {
    Write-Error 'No applications specified for uninstall.'
    exit 1
}

$allApps = Get-KhineInstalledApplications
$selected = @()

foreach ($name in $AppNames) {
    $match = $allApps | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if ($match) {
        $selected += $match
    }
    else {
        Write-Host "Warning: app not found: $name"
    }
}

if ($selected.Count -eq 0) {
    Write-Error 'None of the selected applications were found.'
    exit 1
}

Remove-KhineApplications -Apps $selected
