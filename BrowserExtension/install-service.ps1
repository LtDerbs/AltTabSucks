<#
.SYNOPSIS
    Manages the AltTabSucks scheduled task (auto-start at logon, restarts on crash).

.DESCRIPTION
    Registers server.ps1 as a Task Scheduler task that starts at logon in your
    user session. This is preferable to a Windows service when the script lives
    on a mapped drive (G:) that is only available after you log in.

.PARAMETER Action
    install   - register and immediately start the task (default)
    uninstall - stop and remove the task
    status    - show current task state
    start     - start the task manually (if not already running)
    stop      - stop the running task

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install-service.ps1
    powershell -ExecutionPolicy Bypass -File install-service.ps1 -Action uninstall
#>

param(
    [ValidateSet("install", "uninstall", "status", "start", "stop")]
    [string]$Action = "install"
)

# install and uninstall require admin (Register/Unregister-ScheduledTask with RunLevel Highest).
# Self-elevate via UAC rather than requiring the user to open an admin shell manually.
if ($Action -in "install","uninstall") {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                    [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $argList = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action $Action"
        Start-Process powershell -Verb RunAs -ArgumentList $argList
        exit
    }
}

$TaskName   = "AltTabSucks"
$ScriptPath = Join-Path $PSScriptRoot "server.ps1"

switch ($Action) {

    "install" {
        if (-not (Test-Path $ScriptPath)) {
            Write-Error "server.ps1 not found at: $ScriptPath"
            exit 1
        }

        $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Host "Removing existing '$TaskName' task..."
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }

        $taskAction = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
            -WorkingDirectory $PSScriptRoot

        # Start at logon for the current user only
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"

        # RunLevel Highest is required: HttpListener.Start() on localhost needs elevation
        # (no URL ACL registered). The self-elevation block above handles the UAC prompt.
        $principal = New-ScheduledTaskPrincipal `
            -UserId "$env:USERDOMAIN\$env:USERNAME" `
            -RunLevel Highest `
            -LogonType Interactive

        $settings = New-ScheduledTaskSettingsSet `
            -ExecutionTimeLimit ([TimeSpan]::Zero) `
            -RestartCount 10 `
            -RestartInterval (New-TimeSpan -Minutes 1) `
            -StartWhenAvailable `
            -MultipleInstances IgnoreNew

        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $taskAction `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description "AltTabSucks HTTP server for Chromium/AHK tab integration" `
            -Force | Out-Null

        Write-Host "Task registered. Starting now..."
        Start-ScheduledTask -TaskName $TaskName

        Start-Sleep -Seconds 2
        $info = Get-ScheduledTask -TaskName $TaskName
        $state = $info.State
        Write-Host "Task state: $state"
        if ($state -eq "Running") {
            Write-Host "AltTabSucks is running. Test: curl http://localhost:9876/tabs"
        } else {
            Write-Warning "Task did not reach Running state. Check Event Viewer > Task Scheduler."
        }
    }

    "uninstall" {
        $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-Host "'$TaskName' task is not registered."
        } else {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "Task removed."
        }
    }

    "status" {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-Host "'$TaskName' is not registered."
        } else {
            $info = Get-ScheduledTaskInfo -TaskName $TaskName
            Write-Host "State     : $($task.State)"
            Write-Host "Last run  : $($info.LastRunTime)"
            Write-Host "Last result: $($info.LastTaskResult)"
            Write-Host "Next run  : $($info.NextRunTime)"
        }
    }

    "start" {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-Error "'$TaskName' task is not registered. Run install first."
            exit 1
        }
        if ($task.State -eq "Running") {
            Write-Host "Already running."
        } else {
            Start-ScheduledTask -TaskName $TaskName
            Write-Host "Started."
        }
    }

    "stop" {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task -and $task.State -eq "Running") {
            Stop-ScheduledTask -TaskName $TaskName
            Write-Host "Task stopped."
        } else {
            Write-Host "Task is not running."
        }
        # Kill any orphaned PowerShell processes still holding the port
        # (e.g. from a manual startServer.ps1 run alongside the scheduled task).
        $orphans = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
                   Where-Object { $_.CommandLine -like "*server.ps1*" }
        foreach ($proc in $orphans) {
            Stop-Process -Id $proc.ProcessId -Force
            Write-Host "Killed orphaned server.ps1 process (PID $($proc.ProcessId))."
        }
    }
}
