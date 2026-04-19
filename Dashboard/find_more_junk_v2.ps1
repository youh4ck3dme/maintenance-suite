Function Get-DirSizeGB {
    Param([string]$Path)
    if (Test-Path $Path) {
        $files = Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { return 0 }
        return [Math]::Round($size / 1GB, 2)
    }
    return 0
}

$results = @()

# 1. Dev Junk (node_modules in specific parent dirs)
$devRoots = @("C:\MaintenanceSuite", "$env:USERPROFILE\Documents")
foreach ($root in $devRoots) {
    if (Test-Path $root) {
        $nms = Get-ChildItem -Path $root -Recurse -Directory -Filter "node_modules" -Depth 2 -ErrorAction SilentlyContinue
        foreach ($nm in $nms) {
            $sz = Get-DirSizeGB -Path $nm.FullName
            if ($sz -gt 0.1) {
                $results += [PSCustomObject]@{Category = "Developer Junk (node_modules)"; GB = $sz; Path = $nm.FullName}
            }
        }
    }
}

# 2. Downloads Folder
$dlPath = "$env:USERPROFILE\Downloads"
if (Test-Path $dlPath) {
    $largeFiles = Get-ChildItem -Path $dlPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 500MB }
    foreach ($f in $largeFiles) {
        $results += [PSCustomObject]@{Category = "Large Download File"; GB = [Math]::Round($f.Length / 1GB, 2); Path = $f.FullName}
    }
}

# 3. Spotify/Discord Cache
$spotify = "$env:LOCALAPPDATA\Spotify\Storage"
$discord = "$env:APPDATA\discord\Cache"
$results += [PSCustomObject]@{Category = "Spotify Cache"; GB = (Get-DirSizeGB -Path $spotify); Path = $spotify}
$results += [PSCustomObject]@{Category = "Discord Cache"; GB = (Get-DirSizeGB -Path $discord); Path = $discord}

# 4. Hibernation (if present)
if (Test-Path "C:\hiberfil.sys") {
    $sz = [Math]::Round((Get-Item "C:\hiberfil.sys").Length / 1GB, 2)
    $results += [PSCustomObject]@{Category = "Hibernation File (Can be disabled)"; GB = $sz; Path = "C:\hiberfil.sys"}
}

# 5. Delivery Optimization (Check existence)
$doPath = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path $doPath) {
    # We might not get size due to permissions, but we can mention it.
    $results += [PSCustomObject]@{Category = "Delivery Optimization Cache"; GB = 0; Path = $doPath}
}

$results | Sort-Object GB -Descending | Format-Table -AutoSize
