# Înregistrează aplicația ca Scheduled Task care pornește automat la boot (rulează ca SYSTEM).
# Rulează în PowerShell ca Administrator, după ce run.ps1 -Install a creat venv-ul.
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$action = New-ScheduledTaskAction `
    -Execute (Join-Path $root "venv\Scripts\waitress-serve.exe") `
    -Argument "--host=0.0.0.0 --port=5000 app:app" `
    -WorkingDirectory $root
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName "FlaskHelloOracle" -Action $action -Trigger $trigger `
    -Settings $settings -User "SYSTEM" -RunLevel Highest -Force
Start-ScheduledTask -TaskName "FlaskHelloOracle"
