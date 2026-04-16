# AltTabSucks

ATS is the alt-tab of the future. It is a keyboard shortcut based solution for app-specific window focus control and profile-aware URL-based browser tab focus control. Supports Brave and Chrome at the moment.

---

## Quick Start

### 1. Install prerequisites

Install [AutoHotkey v2](https://www.autohotkey.com/) and PowerShell 7.6+:

```powershell
winget install AutoHotkey.AutoHotkey
winget install Microsoft.PowerShell

# Note: Works for Brave and Chrome, not Edge.
```

### 2. Run the installer

Open a PowerShell 7.6+ prompt in the root AltTabSucks dir and run:

```powershell
.\installer.ps1 -Action install
# Not digitally signed error? Two options:
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
# OR
pwsh -ExecutionPolicy Bypass -File .\installer.ps1 -Action install

```

On first run the server generates a random auth token and saves it to `Server\token.txt` (gitignored). The token is printed to the console — copy it for the next step. To retrieve it later:

```powershell
Get-Content ".\Server\token.txt"
```

### 3. Load the browser extension

1. Go to your browser's extensions page (e.g. `brave://extensions`, `chrome://extensions`)
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked** and select the `BrowserExtension/` folder
4. Open the extension **Options** and set two fields: 
   1. Profile name as it appears in the browser profile menu.
   1. Auth token from copied in prior step.

After the first install, everything starts automatically at logon. To reload the AHK script manually: `Ctrl+Alt+Shift+'`.

### 4. Open up app-hotkeys.ahk and set up your desired shortcuts!

1. Set your profile names as the P1 and P2 values, as they appear in the browser's profile dropdown menu
2. Depending how you have your applications installed, some of the default paths included may need editing.
3. Open your browser, create a new tab to hydrate the extension's localserver, and press Ctrl+Alt+Shift+L to see a debug readout of your current tabs' states. If that looks accurate, you're ready to start using the browser based shortcuts. Have fun!

Done!

---
MORE INFO
installer.ps1 does three things:

1. Registers a Task Scheduler task named **AltTabSucks** that runs `AltTabSucksServer.ps1`:
   - Starts automatically at logon (runs hidden, no console window)
   - Runs with elevated privileges so `HttpListener` can bind to port 9876
2. Writes `AltTabSucks.bat` to your `shell:startup` folder, which waits for the repo directory (handles mapped drive delay at logon) to be available, then launches `AltTabSucks.ahk` automatically on future logons.
3. Launches `AltTabSucks.ahk` immediately so the current session is live without a logon cycle.
---
**Browser auto-detection:** on first launch, AltTabSucks reads your system's default browser from the registry. If it's a supported Chromium browser (Brave, Chrome, Edge, Vivaldi, or Opera), it writes `lib/config.ahk` automatically and shows a brief toast confirming the browser name and paths used. If auto-detection fails (browser not set as the system default, or unsupported), you'll see a dialog — copy `lib/config.template.ahk` to `lib/config.ahk` and fill in the paths manually.
---

## Managing the server task

```powershell
# Check current state (Running / Ready / Disabled)
.\installer.ps1 -Action status

# Start manually (if stopped)
.\installer.ps1 -Action start

# Stop the task and kill any orphaned AltTabSucksServer.ps1 processes
.\installer.ps1 -Action stop

# Remove the task and startup script
.\installer.ps1 -Action uninstall
```

You can also manage it in **Task Scheduler** (`taskschd.msc`) under **Task Scheduler Library > AltTabSucks**.

To run the server manually without a task:

```powershell
.\Server\startServer.ps1
```

---

## For Developers

**Triggering template regeneration**

The pre-commit hook (`hooks/pre-commit`) runs `dev-scripts/make-template.sh` automatically whenever a commit or amend is made, so the templates are always in sync at commit time. The typical workflow after editing `lib/app-hotkeys.ahk`:

```bash
# Stage any other tracked changes, then amend the top commit to include the template update:
git commit --amend --no-edit
# The hook fires, regenerates both templates, and stages them into the amend automatically.
```

To regenerate templates manually without committing:

```bash
./dev-scripts/make-template.sh
```

Run `bash dev-scripts/install-hooks.sh` once after cloning to activate the hook.

---

## Troubleshooting

**Task registers but does not reach Running state**

Open Event Viewer: `eventvwr.msc` → **Windows Logs > Application**, or
**Applications and Services Logs > Microsoft > Windows > TaskScheduler > Operational**.
Look for errors referencing the AltTabSucks task.

**Port 9876 already in use**

Another instance of `AltTabSucksServer.ps1` is running. Stop it:

```powershell
.\installer.ps1 -Action stop
# or find the PID manually:
netstat -ano | findstr :9876
# then: taskkill /PID <pid> /F
```

**Extension shows "server offline"**

- Confirm the task is running: `.\installer.ps1 -Action status`
- Check the extension Options page has the correct profile name set

**Extension shows "server: error (403)"**

The auth token in the extension Options doesn't match `Server\token.txt`. Retrieve the correct token:

```powershell
Get-Content ".\Server\token.txt"
```

Paste it into the extension **Options** page and save.

**Extension shows "server offline" but the task is Running**

The port may be held by an orphaned process from a previous manual run:

```powershell
.\installer.ps1 -Action stop
.\installer.ps1 -Action start
```                                    |
