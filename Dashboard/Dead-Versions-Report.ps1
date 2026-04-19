Write-Host "Scanning for potentially broken/redundant versions (> 500MB)..." -ForegroundColor Cyan

$searchPaths = @(
    "$env:USERPROFILE\Documents\root-g15-moto",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents"
)

$junkExtensions = @(".img", ".iso", ".xz", ".zip", ".tar", ".apk", ".vhdx")

$results = foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { ($_.Length -gt 500MB) -and ($junkExtensions -contains $_.Extension) }
    }
}

if ($results) {
    $results | Select-Object Name, @{Name="GB";Expression={[Math]::Round($_.Length / 1GB, 2)}}, FullName | 
    Sort-Object GB -Descending | Format-Table -AutoSize
} else {
    Write-Host "No large redundant versions found in these paths." -ForegroundColor Yellow
}
