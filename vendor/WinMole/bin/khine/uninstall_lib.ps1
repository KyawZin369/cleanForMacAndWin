# Shared uninstall discovery/removal for Khine GUI adapters.
#Requires -Version 5.1

. "$PSScriptRoot\_common.ps1"
. (Join-Path $script:WINMOLE_LIB 'core\file_ops.ps1')

$script:ProtectedApps = @(
    'Microsoft Windows'
    'Windows Feature Experience Pack'
    'Microsoft Edge'
    'Microsoft Edge WebView2'
    'Windows Security'
    'Microsoft Visual C++ *'
    'Microsoft .NET *'
    '.NET Desktop Runtime*'
    'Microsoft Update Health Tools'
    'NVIDIA Graphics Driver*'
    'AMD Software*'
    'Intel*Driver*'
)

function Test-ProtectedAppName {
    param([string]$AppName)
    foreach ($pattern in $script:ProtectedApps) {
        if ($AppName -like $pattern) { return $true }
    }
    return $false
}

function Get-KhineInstalledApplications {
    $apps = @()

    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($path in $registryPaths) {
        try {
            $regItems = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            foreach ($item in $regItems) {
                $displayName = $null
                $uninstallString = $null
                try { $displayName = $item.DisplayName } catch { }
                try { $uninstallString = $item.UninstallString } catch { }
                if ([string]::IsNullOrWhiteSpace($displayName) -or [string]::IsNullOrWhiteSpace($uninstallString)) {
                    continue
                }
                if (Test-ProtectedAppName $displayName) { continue }

                $sizeKB = 0
                try {
                    if ($item.EstimatedSize) { $sizeKB = [long]$item.EstimatedSize }
                    elseif ($item.InstallLocation -and (Test-Path $item.InstallLocation -ErrorAction SilentlyContinue)) {
                        $sizeKB = Get-PathSizeKB -Path $item.InstallLocation
                    }
                }
                catch { }

                $installLocation = $null
                try { $installLocation = $item.InstallLocation } catch { }

                $apps += [PSCustomObject]@{
                    Name            = $displayName
                    Publisher       = $(try { $item.Publisher } catch { $null })
                    SizeKB          = $sizeKB
                    SizeHuman       = Format-HumanSize -Bytes ($sizeKB * 1024)
                    InstallLocation = $installLocation
                    UninstallString = $uninstallString
                    PackageFullName = $null
                    Source          = 'Registry'
                }
            }
        }
        catch { }
    }

    try {
        Get-AppxPackage -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IsFramework -eq $false -and
                $_.SignatureKind -ne 'System' -and
                -not (Test-ProtectedAppName $_.Name)
            } |
            ForEach-Object {
                $name = $_.Name
                try {
                    $manifest = Get-AppxPackageManifest -Package $_.PackageFullName -ErrorAction SilentlyContinue
                    if ($manifest.Package.Properties.DisplayName -and
                        -not $manifest.Package.Properties.DisplayName.StartsWith('ms-resource:')) {
                        $name = $manifest.Package.Properties.DisplayName
                    }
                }
                catch { }

                $sizeKB = 0
                if ($_.InstallLocation -and (Test-Path $_.InstallLocation)) {
                    $sizeKB = Get-PathSizeKB -Path $_.InstallLocation
                }

                $apps += [PSCustomObject]@{
                    Name            = $name
                    Publisher       = $_.Publisher
                    SizeKB          = $sizeKB
                    SizeHuman       = Format-HumanSize -Bytes ($sizeKB * 1024)
                    InstallLocation = $_.InstallLocation
                    UninstallString = $null
                    PackageFullName = $_.PackageFullName
                    Source          = 'WindowsStore'
                }
            }
    }
    catch { }

    return , ($apps | Sort-Object SizeKB -Descending)
}

function Remove-KhineApplications {
    param([array]$Apps)

    $successCount = 0
    $failCount = 0

    foreach ($app in $Apps) {
        Write-Host "Uninstalling: $($app.Name)"
        try {
            if ($app.Source -eq 'WindowsStore' -and $app.PackageFullName) {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction Stop
                Write-Host "  Removed $($app.Name)"
                $successCount++
            }
            elseif ($app.UninstallString) {
                $uninstallString = $app.UninstallString
                if ($uninstallString -like 'MsiExec.exe*') {
                    $productCode = [regex]::Match($uninstallString, '\{[0-9A-F-]+\}').Value
                    if ($productCode) {
                        $process = Start-Process -FilePath 'msiexec.exe' `
                            -ArgumentList '/x', $productCode, '/qn', '/norestart' `
                            -Wait -PassThru -NoNewWindow
                        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                            Write-Host "  Removed $($app.Name)"
                            $successCount++
                        }
                        else {
                            throw "msiexec exit $($process.ExitCode)"
                        }
                    }
                }
                else {
                    $process = Start-Process -FilePath 'cmd.exe' `
                        -ArgumentList '/c', "`"$uninstallString`" /S /silent /quiet" `
                        -Wait -PassThru -NoNewWindow
                    if ($process.ExitCode -eq 0) {
                        Write-Host "  Removed $($app.Name)"
                        $successCount++
                    }
                    else {
                        throw "uninstaller exit $($process.ExitCode)"
                    }
                }
            }

            if ($app.InstallLocation -and (Test-Path $app.InstallLocation)) {
                Remove-SafeItem -Path $app.InstallLocation -Description 'Leftover files' -Recurse
            }
        }
        catch {
            Write-Host "  Failed to remove $($app.Name): $_"
            $failCount++
        }
    }

    Write-Host ''
    Write-Host "Uninstall complete. Removed $successCount app(s)."
    if ($failCount -gt 0) {
        Write-Host "Failed: $failCount app(s)."
        exit 1
    }
}
