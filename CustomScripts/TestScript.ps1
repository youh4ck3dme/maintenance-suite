# TestScript.ps1
# Example of an extensible script for the Maintenance Suite.

Write-Host "Hello from Custom Script! This is working."
Add-Content -Path "C:\MaintenanceSuite\cleanup.log" -Value "[(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Hello from Custom Script!"
