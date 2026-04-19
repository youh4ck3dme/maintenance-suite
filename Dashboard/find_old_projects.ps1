$targetRoots = @(
    "C:\MaintenanceSuite",
    "C:\Users\42195\Documents",
    "C:\Users\42195\Desktop"
)

$thresholdDate = (Get-Date).AddDays(-30)
$projects = @()

Function Get-FolderSizeGB {
    Param([string]$Path)
    if (Test-Path $Path) {
        $files = Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $size) { return 0 }
        return [Math]::Round($size / 1GB, 2)
    }
    return 0
}

foreach ($root in $targetRoots) {
    if (Test-Path $root) {
        # Find directories that have package.json or .git
        $potentialProjects = Get-ChildItem -Path $root -Directory -Depth 1 -ErrorAction SilentlyContinue | Where-Object {
            (Test-Path (Join-Path $_.FullName "package.json")) -or (Test-Path (Join-Path $_.FullName ".git"))
        }

        foreach ($p in $potentialProjects) {
            if ($p.LastWriteTime -lt $thresholdDate) {
                $projects += [PSCustomObject]@{
                    Name = $p.Name
                    LastModified = $p.LastWriteTime
                    Path = $p.FullName
                    SizeGB = Get-FolderSizeGB -Path $p.FullName
                }
            }
        }
    }
}

$projects | Sort-Object LastModified | Format-Table -AutoSize
