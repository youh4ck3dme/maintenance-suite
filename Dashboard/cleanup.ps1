$targets = @(
    $env:TEMP,
    "C:\Windows\Temp",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
)

Write-Output "Stopping Windows Update service..."
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

Write-Output "Cleaning directories..."
foreach ($path in $targets) {
    if (Test-Path $path) {
        Write-Output "Cleaning $path"
        try {
            Get-ChildItem -Path $path -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        } catch {
            Write-Output "Error cleaning $path"
        }
    }
}

$updatePath = "C:\Windows\SoftwareDistribution\Download"
if (Test-Path $updatePath) {
    Write-Output "Cleaning $updatePath"
    try {
        Get-ChildItem -Path $updatePath -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    } catch {
        Write-Output "Error cleaning $updatePath"
    }
}

Write-Output "Restarting Windows Update service..."
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

Write-Output "Emptying Recycle Bin..."
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
} catch {
    Write-Output "Error emptying Recycle Bin"
}

Write-Output "Cleanup complete."
