$results = @()

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

# 1. Delivery Optimization
$doPath = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
$size = Get-DirSizeGB -Path $doPath
$results += [PSCustomObject]@{Category = "Delivery Optimization Cache"; GB = $size; Path = $doPath}

# 2. Windows.old
$size = Get-DirSizeGB -Path "C:\Windows.old"
$results += [PSCustomObject]@{Category = "Previous Windows Installations"; GB = $size; Path = "C:\Windows.old"}

# 3. Hibernation File
if (Test-Path "C:\hiberfil.sys") {
    $size = [Math]::Round((Get-Item "C:\hiberfil.sys").Length / 1GB, 2)
    $results += [PSCustomObject]@{Category = "Hibernation File"; GB = $size; Path = "C:\hiberfil.sys"}
}

# 4. Spotify Cache
$spotifyPath = "$env:LOCALAPPDATA\Spotify\Storage"
$size = Get-DirSizeGB -Path $spotifyPath
$results += [PSCustomObject]@{Category = "Spotify Cache"; GB = $size; Path = $spotifyPath}

# 5. Developer Junk (node_modules in common places)
$devPaths = @("C:\MaintenanceSuite", "C:\Users\42195\Documents")
foreach ($p in $devPaths) {
    if (Test-Path $p) {
        $nms = Get-ChildItem -Path $p -Recurse -Directory -Filter "node_modules" -Depth 2 -ErrorAction SilentlyContinue
        foreach ($nm in $nms) {
            $size = Get-DirSizeGB -Path $nm.FullName
            if ($size -gt 0.1) {
                $results += [PSCustomObject]@{Category = "Dev Junk: " + $nm.FullName; GB = $size; Path = $nm.FullName}
            }
        }
    }
}

# 6. Large ZIP/ISO/EXE in Downloads
$dlPath = "C:\Users\42195\Downloads"
if (Test-Path $dlPath) {
    $largeFiles = Get-ChildItem -Path $dlPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 500MB }
    foreach ($f in $largeFiles) {
        $results += [PSCustomObject]@{Category = "Large Download: " + $f.Name; GB = [Math]::Round($f.Length / 1GB, 2); Path = $f.FullName}
    }
}

$results | Sort-Object GB -Descending | Format-Table -AutoSize
