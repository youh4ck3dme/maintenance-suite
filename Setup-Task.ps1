# Setup-Task.ps1
# This script registers a daily Task Scheduler task to run the cleanup.

$TaskName = "DailyCleanupTask"
$TaskDescription = "Runs BleachBit and custom maintenance scripts every 24 hours."
$ActionScript = "C:\MaintenanceSuite\Run-Cleanup.ps1"
$Time = (Get-Date).AddMinutes(5).ToString("HH:mm") # Starts 5 minutes from now by default

# 1. Action: Run PowerShell script hidden
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ActionScript`""

# 2. Trigger: Daily at specified time
$Trigger = New-ScheduledTaskTrigger -Daily -At $Time

# 3. Principal: Run as current user
$Principal = New-ScheduledTaskPrincipal -UserId "$($env:USERDOMAIN)\$($env:USERNAME)" -LogonType Interactive

# 4. Settings: Allow wake to run, run as soon as possible after scheduled time if missed
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)

# Register the task (overwrite if exists)
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -TaskName $TaskName -Description $TaskDescription

Write-Host "Task '$TaskName' registered successfully to run daily at $Time."
Write-Host "You can change the time in Task Scheduler (taskschd.msc)."
