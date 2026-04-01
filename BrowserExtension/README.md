# AltTabSucks

HTTP server, Chromium browser extension, and AutoHotkey for
profile-aware tab switching. Works with any Chromium-based browser (Brave, Chrome, Edge, Vivaldi).

## Components

| File | Purpose |
|---|---|
| `server.ps1` | PowerShell HTTP server on `localhost:9876` |
| `background.js` | Chromium MV3 extension service worker |
| `install-service.ps1` | Registers `server.ps1` as a Windows scheduled task |

---

## First-time setup

### 1. Load the browser extension

1. Open your browser and go to its extensions page (e.g. `brave://extensions`, `chrome://extensions`)
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked** and select the `AltTabSucks` folder
4. Open the extension **Options** and set your profile name (e.g. `Default`)

### 2. Register the scheduled task

Run from any PowerShell prompt (the script will trigger a UAC prompt for the admin step):

```powershell
powershell -ExecutionPolicy Bypass -File ".\install-service.ps1"
```

This registers a Task Scheduler task named **AltTabSucks** that:
- Starts automatically at logon (runs hidden, no console window)
- Restarts automatically if it crashes (up to 10 times, 1 minute apart)
- Runs with elevated privileges so `HttpListener` can bind to port 9876

Verify it started:

```powershell
curl http://localhost:9876/tabs
```

You should get `{}` or a JSON object back.

---

## Managing the task

```powershell
# Check current state (Running / Ready / Disabled)
.\install-service.ps1 -Action status

# Start manually (if stopped)
.\install-service.ps1 -Action start

# Stop
.\install-service.ps1 -Action stop

# Remove the task entirely
.\install-service.ps1 -Action uninstall
```

You can also manage it in **Task Scheduler** (`taskschd.msc`) under
**Task Scheduler Library > AltTabSucks**.

---

## Running the server manually (no task)

```powershell
powershell -ExecutionPolicy Bypass -File server.ps1
```

Press `Ctrl+C` to stop.

---

## Troubleshooting

**Task registers but does not reach Running state**

Open Event Viewer: `eventvwr.msc` > **Windows Logs > Application**, or
**Applications and Services Logs > Microsoft > Windows > TaskScheduler > Operational**.
Look for errors referencing the AltTabSucks task.

**Port 9876 already in use**

Another instance of `server.ps1` is running. Stop it:

```powershell
.\install-service.ps1 -Action stop
# or find the PID:
netstat -ano | findstr :9876
# then: taskkill /PID <pid> /F
```

**Extension shows "server offline"**

- Confirm the task is running: `.\install-service.ps1 -Action status`
- Test the endpoint: `curl http://localhost:9876/tabs`
- Check the extension options page has the correct profile name set
