# Khine adapter: installed apps JSON list for the Flutter UI.
#Requires -Version 5.1

. "$PSScriptRoot\uninstall_lib.ps1"

$apps = Get-KhineInstalledApplications
$payload = @()

foreach ($app in $apps) {
    $bundleId = if ($app.PackageFullName) { $app.PackageFullName } else { $app.Name }
    $payload += [ordered]@{
        name           = $app.Name
        bundle_id      = $bundleId
        source         = $app.Source
        uninstall_name = $app.Name
        path           = $app.InstallLocation
        size           = $app.SizeHuman
    }
}

Write-KhineJson -Payload $payload
