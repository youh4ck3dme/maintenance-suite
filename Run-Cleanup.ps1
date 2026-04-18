# Run-Cleanup.ps1
# This script performs daily maintenance cleanup.
param (
    [switch]$Silent
)

$LogFile = "C:\MaintenanceSuite\cleanup.log"
$CustomScriptsDir = "C:\MaintenanceSuite\CustomScripts"

function Write-Log($Message) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
}

function Get-FolderSize($Path) {
    if (-not (Test-Path $Path)) { return 0 }
    return (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
}

$PathsToMeasure = @{
    "NPM Cache" = "$env:AppData\npm-cache"
    "PNPM Store" = "$env:LocalAppData\pnpm\store"
    "System Temp" = $env:TEMP
}

$BeforeStats = @{}
foreach ($name in $PathsToMeasure.Keys) {
    $BeforeStats[$name] = Get-FolderSize $PathsToMeasure[$name]
}

# 1. Pop-up Confirmation
Add-Type -AssemblyName System.Windows.Forms
$nl = [System.Environment]::NewLine
$Message = "Zoznam akcií na vykonanie:$nl$nl" +
           "✅ Čistenie BleachBit (system.tmp, system.cache)$nl" +
           "✅ Čistenie NPM Cache (npm cache clean --force)$nl" +
           "✅ Čistenie PNPM Store (pnpm store prune)$nl" +
           "✅ Spustenie vlastných skriptov (CustomScripts)$nl$nl" +
           "Chcete pokračovať s automatickým čistením?"

if ($Silent) {
    Write-Log "Silent mode active. Skipping confirmation."
    $Result = 'Yes'
} else {
    $Result = [System.Windows.Forms.MessageBox]::Show($Message, "Potvrdenie čistenia", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

if ($Result -eq 'No') {
    Write-Log "Čistenie zrušené používateľom."
    exit
}

Write-Log "--- Starting Maintenance Cleanup ---"

# 2. BleachBit Cleanup
$BleachBitPaths = @(
    "C:\Program Files (x86)\BleachBit\bleachbit_console.exe",
    "C:\Program Files\BleachBit\bleachbit_console.exe",
    "bleachbit_console.exe"
)

$BleachBitFound = $false
foreach ($Path in $BleachBitPaths) {
    if (Get-Command $Path -ErrorAction SilentlyContinue) {
        Write-Log "BleachBit found: $Path"
        try {
            & $Path --clean system.tmp system.cache | Out-String | Write-Log
            Write-Log "BleachBit cleanup completed."
            $BleachBitFound = $true
            break
        } catch {
            Write-Log "ERROR: BleachBit failed to run: $_"
        }
    }
}
if (-not $BleachBitFound) { Write-Log "WARNING: BleachBit not found. Skipping." }

# 3. NPM Cache Cleanup
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Log "Cleaning NPM cache..."
    npm cache clean --force 2>&1 | Out-String | Write-Log
}

# 4. PNPM Store Cleanup
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Write-Log "Pruning PNPM store..."
    pnpm store prune 2>&1 | Out-String | Write-Log
}

# 5. Extensible Custom Scripts
if (Test-Path $CustomScriptsDir) {
    Get-ChildItem -Path $CustomScriptsDir -Include *.ps1, *.bat -Recurse | ForEach-Object {
        Write-Log "Executing custom script: $($_.Name)"
        try {
            if ($_.Extension -eq ".ps1") {
                & $_.FullName | Out-String | Write-Log
            } else {
                Start-Process -FilePath $_.FullName -Wait -NoNewWindow
            }
            Write-Log "Custom script $($_.Name) finished."
        } catch {
            Write-Log "ERROR: Custom script $($_.Name) failed: $_"
        }
    }
}

Write-Log "--- Maintenance Cleanup Finished ---"

# --- Calculate After Stats and Save To History ---
$AfterStats = @{}
$TotalFreed = 0
$Breakdown = @()

foreach ($name in $PathsToMeasure.Keys) {
    $after = Get-FolderSize $PathsToMeasure[$name]
    $before = $BeforeStats[$name]
    $freed = [Math]::Max(0, $before - $after)
    $TotalFreed += $freed
    
    $AfterStats[$name] = $after
    $Breakdown += @{
        category = $name
        before = [Math]::Round($before, 2)
        after = [Math]::Round($after, 2)
        freed = [Math]::Round($freed, 2)
    }
}

$HistoryFile = "C:\MaintenanceSuite\Dashboard\backend\history.json"
$History = if (Test-Path $HistoryFile) { Get-Content $HistoryFile | ConvertFrom-Json } else { @() }

$NewEntry = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalFreedMB = [Math]::Round($TotalFreed, 2)
    breakdown = $Breakdown
}

$History = @($NewEntry) + $History | Select-Object -First 10
$History | ConvertTo-Json -Depth 4 | Set-Content $HistoryFile

Write-Log "Summary: Freed $([Math]::Round($TotalFreed, 2)) MB in total."
