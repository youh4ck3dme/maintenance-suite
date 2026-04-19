Write-Host "Searching for Large Files in User Profile..." -ForegroundColor Cyan

# Find files > 1GB in Downloads and Documents
$userPaths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Documents", "$env:LOCALAPPDATA")

$files = foreach ($p in $userPaths) {
    if (Test-Path $p) {
        Get-ChildItem -Path $p -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1GB }
    }
}

if ($files) {
    $files | Select-Object Name, @{Name="GB";Expression={[Math]::Round($_.Length / 1GB, 2)}}, FullName | Sort-Object GB -Descending | Format-Table -AutoSize
} else {
    Write-Host "No files > 1GB found in primary user folders." -ForegroundColor Yellow
}

# Check for massive AppData folders
Write-Host "`nScanning AppData size (Top 5 subfolders)..." -ForegroundColor Cyan
Get-ChildItem -Path "$env:LOCALAPPDATA" -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size -gt 100MB) {
        [PSCustomObject]@{Path = $_.FullName; GB = [Math]::Round($size / 1GB, 2)}
    }
} | Sort-Object GB -Descending | Select-Object -First 5 | Format-Table -AutoSize
