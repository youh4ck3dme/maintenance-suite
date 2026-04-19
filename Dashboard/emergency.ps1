Write-Host "--- EMERGENCY DEEP CLEAN START ---" -ForegroundColor Red

# 1. Stop Windows Update & Clean
Write-Host "[1/3] Hard cleaning Windows Update Cache..." -ForegroundColor Yellow
net stop wuauserv
net stop bits
Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
net start wuauserv
net start bits

# 2. Deep Temp Clean (System & All Users)
Write-Host "[2/3] Cleaning all Temp locations..." -ForegroundColor Yellow
$tempPaths = @(
    "C:\Windows\Temp\*",
    "$env:LOCALAPPDATA\Temp\*",
    "C:\Windows\Prefetch\*",
    "C:\Users\*\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db"
)
foreach ($path in $tempPaths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Locate "The Big Ones" (> 2GB)
Write-Host "[3/3] Locating files larger than 2GB in C:\Users..." -ForegroundColor Cyan
Get-ChildItem -Path "C:\Users" -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 2GB } | Select-Object FullName, @{Name="GB";Expression={[Math]::Round($_.Length / 1GB, 2)}} | Sort-Object GB -Descending | Format-Table -AutoSize

Write-Host "--- EMERGENCY CLEAN FINISHED ---" -ForegroundColor Red
