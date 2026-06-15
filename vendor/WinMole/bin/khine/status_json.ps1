# Khine adapter: system status JSON for the Flutter UI.
#Requires -Version 5.1

. "$PSScriptRoot\_common.ps1"

function Format-Uptime {
    param([TimeSpan]$Span)
    $parts = @()
    if ($Span.Days -gt 0) { $parts += '{0}d' -f $Span.Days }
    if ($Span.Hours -gt 0) { $parts += '{0}h' -f $Span.Hours }
    if ($Span.Minutes -gt 0 -and $Span.Days -eq 0) { $parts += '{0}m' -f $Span.Minutes }
    if ($parts.Count -eq 0) { return '0m' }
    return ($parts -join ' ')
}

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$logicalCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

$cpuLoad = 0.0
try {
    $sample = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
    $cpuLoad = [double]$sample.Average
}
catch { }

$memTotal = [long]$os.TotalVisibleMemorySize * 1024
$memFree = [long]$os.FreePhysicalMemory * 1024
$memUsed = [math]::Max(0, $memTotal - $memFree)
$memPercent = if ($memTotal -gt 0) { ($memUsed / $memTotal) * 100 } else { 0 }

$pageTotal = [long]($os.TotalVirtualMemorySize - $os.TotalVisibleMemorySize) * 1024
$pageFree = [long]($os.FreeVirtualMemory - $os.FreePhysicalMemory) * 1024
$pageUsed = [math]::Max(0, $pageTotal - $pageFree)

$boot = $os.LastBootUpTime
$uptime = if ($boot) { Format-Uptime -Span ((Get-Date) - $boot) } else { '' }

$disks = @()
$driveIndex = 0
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total = [long]$_.Size
    $free = [long]$_.FreeSpace
    $used = [math]::Max(0, $total - $free)
    $usedPercent = if ($total -gt 0) { ($used / $total) * 100 } else { 0 }
    $driveIndex++
    $disks += [ordered]@{
        mount         = $_.DeviceID
        device        = $_.VolumeName
        used          = $used
        total         = $total
        used_percent  = [math]::Round($usedPercent, 1)
        external      = $false
    }
}

$network = @()
try {
    $adapters = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' }
    foreach ($adapter in ($adapters | Select-Object -First 3)) {
        $network += [ordered]@{
            name       = $adapter.InterfaceAlias
            ip         = $adapter.IPAddress
            rx_rate_mbs = 0
            tx_rate_mbs = 0
        }
    }
}
catch { }

$processes = @()
try {
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 8 | ForEach-Object {
        $memMb = 0.0
        try { $memMb = $_.WorkingSet64 / 1MB } catch { }
        $processes += [ordered]@{
            name    = $_.ProcessName
            command = $_.ProcessName
            cpu     = [math]::Round([double]$_.CPU, 1)
            memory  = [math]::Round($memMb, 1)
        }
    }
}
catch { }

$health = 100
if ($cpuLoad -gt 85) { $health -= 20 }
elseif ($cpuLoad -gt 65) { $health -= 10 }
if ($memPercent -gt 90) { $health -= 20 }
elseif ($memPercent -gt 75) { $health -= 10 }
if ($disks.Count -gt 0 -and $disks[0].used_percent -gt 90) { $health -= 15 }
$health = [math]::Max(0, [math]::Min(100, $health))

$healthMsg = switch ($health) {
    { $_ -ge 90 } { 'System is running smoothly' }
    { $_ -ge 70 } { 'System is healthy with minor load' }
    default { 'System is under pressure' }
}

Write-KhineJson -Payload ([ordered]@{
    collected_at      = (Get-Date).ToString('o')
    host              = $env:COMPUTERNAME
    uptime            = $uptime
    health_score      = $health
    health_score_msg  = $healthMsg
    cpu               = [ordered]@{
        usage = [math]::Round($cpuLoad, 1)
        model = $cpu.Name
        logical_cpu = $logicalCores
    }
    memory            = [ordered]@{
        used          = $memUsed
        total         = $memTotal
        available     = $memFree
        used_percent  = [math]::Round($memPercent, 1)
        swap_used     = $pageUsed
        swap_total    = $pageTotal
    }
    disks             = $disks
    trash_size        = 0
    disk_io           = [ordered]@{
        read_rate  = 0
        write_rate = 0
    }
    top_processes     = $processes
    network           = $network
    proxy             = [ordered]@{
        enabled = $false
        type    = ''
        host    = ''
    }
    batteries         = @()
})
