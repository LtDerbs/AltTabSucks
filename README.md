# AltTabSucks

AutoHotkey v2 automation scripts for Windows productivity — window cycling, Chromium browser profile switching, and profile-aware tab control via a local HTTP bridge. Works with any Chromium-based browser (Brave, Chrome, Edge, Vivaldi, Opera).

---

## Quick Start

### 1. Install prerequisites

Install [AutoHotkey v2](https://www.autohotkey.com/) and PowerShell 7.6+:

```powershell
winget install AutoHotkey.AutoHotkey
winget install Microsoft.PowerShell
```

### 2. Run the installer

Open a PowerShell 7.6+ prompt in the root AltTabSucks dir and run:

```powershell
.\installer.ps1 -Action install
```

This does three things:

1. Registers a Task Scheduler task named **AltTabSucks** that runs `AltTabSucksServer.ps1`:
   - Starts automatically at logon (runs hidden, no console window)
   - Runs with elevated privileges so `HttpListener` can bind to port 9876
2. Writes `AltTabSucks.bat` to your `shell:startup` folder, which waits for the repo directory (handles mapped drive delay at logon) to be available, then launches `AltTabSucks.ahk` automatically on future logons.
3. Launches `AltTabSucks.ahk` immediately so the current session is live without a logon cycle.

**Browser auto-detection:** on first launch, AltTabSucks reads your system's default browser from the registry. If it's a supported Chromium browser (Brave, Chrome, Edge, Vivaldi, or Opera), it writes `lib/config.ahk` automatically and shows a brief toast confirming the browser name and paths used. If auto-detection fails (browser not set as the system default, or unsupported), you'll see a dialog — copy `lib/config.template.ahk` to `lib/config.ahk` and fill in the paths manually.

On first run the server generates a random auth token and saves it to `Server\token.txt` (gitignored). The token is printed to the console — copy it for the next step. To retrieve it later:

```powershell
Get-Content ".\Server\token.txt"
```

### 3. Load the browser extension

1. Go to your browser's extensions page (e.g. `brave://extensions`, `chrome://extensions`)
2. Enable **Developer mode** (top-right toggle)
3. Click **Load unpacked** and select the `BrowserExtension/` folder
4. Open the extension **Options** — set your profile name and paste the auth token from step 2. The name must match the displayed name of your profile in the browser profile menu.


After the first install, everything starts automatically at logon. To reload the AHK script manually: `Ctrl+Alt+Shift+'`. To debug: right-click the tray icon → Window Spy.

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

## Adding Hotkeys

Edit `lib/app-hotkeys.ahk` (gitignored — contains real URLs/paths, never committed directly). The tracked counterpart is `lib/app-hotkeys.template.ahk`, which has all sensitive values redacted.


## Hotkey Conventions


| Modifier | Meaning      |
| -------- | ------------ |
| `^`      | Ctrl         |
| `!`      | Alt          |
| `+`      | Shift        |
| `#`      | Win          |

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
```

## Components


| Path                                   | Purpose                                                                                               |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `AltTabSucks.ahk`                      | Entry point — self-elevates and includes all libs                                                     |
| `lib/utils.ahk`                        | Window management (`ManageAppWindows`, `ShowTextGui`)                                                 |
| `lib/config.ahk`                       | Machine-local config: `CHROMIUM_EXE`, `CHROMIUM_USERDATA` (**gitignored** — auto-generated on first launch, see `config.template.ahk`) |
| `lib/config.template.ahk`              | Sanitized config template, tracked in git                                                             |
| `lib/chromium.ahk`                     | Chromium profile cycling + tab focus via AltTabSucks                                                  |
| `lib/toast.ahk`                        | Visual feedback overlays                                                                              |
| `lib/star-citizen.ahk`                 | Star Citizen–scoped hotkeys                                                                           |
| `lib/app-hotkeys.ahk`                  | General app/browser hotkeys (**gitignored** — contains real paths/URLs)                               |
| `lib/app-hotkeys.template.ahk`         | Sanitized version of above, tracked in git                                                            |
| `installer.ps1`                        | Full install: scheduled task + startup script + immediate launch                                      |
| `Server/AltTabSucksServer.ps1`         | PowerShell HTTP server on `localhost:9876`                                                            |
| `Server/startServer.ps1`               | Manually start the server (no scheduled task)                                                         |
| `BrowserExtension/background.js`       | Chromium MV3 extension service worker                                                                 |
| `screenOff.ps1`                        | Turn off monitor                                                                                      |
| `dev-scripts/make-template.sh`         | Regenerate sanitized templates from the gitignored source files                                       |
| `hooks/pre-commit`                     | Git pre-commit hook — auto-runs `make-template.sh` on commit                                          |
| `dev-scripts/install-hooks.sh`         | Install tracked hooks into `.git/hooks/` (run once after cloning)                                     |
