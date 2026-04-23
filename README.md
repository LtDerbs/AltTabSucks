# AltTabSucks

ATS is the alt-tab of the future: a keyboard shortcut based solution for app-specific window focus control, profile-aware URL-based browser tab focus control, and more. Supports Brave, Chrome and Firefox at the moment. Windows only for now.

**Features:**
- **App window management** — cycle or toggle any app's windows with a single hotkey; launch it if it isn't running
- **Browser tab focus** — jump to a tab by URL pattern for a given browser profile; opens the URL if no matching tab exists
- **Browser profile cycling** — cycle through all windows for a given browser profile
- **Split/merge tab snapping** — tear the active tab into its own window and snap both halves side-by-side; merge them back with another hotkey

---

## Quick Start

### 1. Install prerequisites

**PowerShell 7.6+** is required:

```powershell
winget install AutoHotkey.AutoHotkey
winget install Microsoft.PowerShell
winget install Git.Git

```

### 2. Clone the repo and run the installer

Open a PowerShell 7.6+ prompt in the root AltTabSucks dir and run:

```powershell
cd "$env:USERPROFILE\Downloads"
git clone https://github.com/tomatointhesand/AltTabSucks
cd AltTabSucks
.\installer.ps1 -Action install
# Not digitally signed error? Two options:
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
# OR
pwsh -ExecutionPolicy Bypass -File .\installer.ps1 -Action install

```

Installer will display an auth token - **copy it to clipboard**. (It is also saved to `Server\token.txt` (gitignored) for future reference.)

### 3. Install and configure the browser extension

   1. Install the extension:
      <details>
      <summary>Chrome-like</summary>

         1. Go to your browser's extensions page (e.g. `brave://extensions`, `chrome://extensions`)
         1. Enable **Developer mode** (top-right toggle)
         1. Click **Load unpacked** and select the `AltTabSucks/BrowserExtension` folder
      </details>

      <details>
      <summary>Firefox</summary>
   
      1. Go to `about:addons`
      1. Install `AltTabSucks/AltTabSucks-firefox.xpi`
      </details>

   Then open the extension **Options** and set two fields:
   * **Auth token** — paste the token copied from the prior step, then refresh the next field's dropdown
   * **Profile name** — select the active profile name from the dropdown
     * to figure out the active profile name:
         * Firefox: Open **about:profiles**
         * Chrome-like: the top-right Profile menu dropdown displays the active profile name

   After the first install, everything starts automatically at logon. To reload the AHK script manually: `Ctrl+Alt+Shift+'`.




### 4. Open lib\app-hotkeys.ahk

1. Set the P1 var value to the same profile name as set in the extension options. P2 can be set for a second browser profile if you use one.
   * Note: Depending how you have your applications installed, some of the included app paths included may need editing.
1. Open your browser and switch tabs to hydrate the extension's localserver
   * **Press Ctrl+Alt+Shift+/** (forward slash) **to see a quick reference for all mapped hotkeys**
   * Press Ctrl+Alt+Shift+L to see a debug readout of your current tabs' states
1. Come back to this file any time to edit hotkey triggers, add apps, urls, etc as desired.
1. All done, have fun!


---
## MORE INFO

`installer.ps1 -Action install` does four things:

1. Registers a Task Scheduler task named **AltTabSucks** that runs `AltTabSucksServer.ps1`:
   - Starts automatically at logon (runs hidden, no console window)
   - Runs with elevated privileges so `HttpListener` can bind to port 9876
2. Writes `AltTabSucks.bat` to your `shell:startup` folder, then launches `AltTabSucks.ahk` automatically on future logons.
3. Disables the **Ctrl+Alt+Win+Shift** shortcut that opens Copilot/Office by redirecting the `ms-officeapp` protocol handler to a no-op (`rundll32`).
4. Launches `AltTabSucks.ahk` immediately so the current session is live without a logon cycle.

---
Browser selection:

On first launch (or after reinstalling), AltTabSucks scans for installed browsers and presents a choice dialog. Supported browsers: **Brave, Chrome, Firefox**. After choosing, you will be offered the option to open Windows Default Apps to verify or set your system default browser. The chosen browser and its paths are saved to `lib/config.ahk` (gitignored). To switch browsers later, re-run the installer — it deletes `lib/config.ahk` so the choice dialog reappears on next launch.

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

**Packaging the Firefox extension**

Produces a signed `.xpi` for sideloading. Requires Node.js (the script offers to install via `winget` if missing) and AMO credentials (prompted on first run, stored in `.amo-credentials`).

```powershell
# Unsigned zip only (for local testing via about:debugging):
.\dev-scripts\package-firefox-extension.ps1

# Signed xpi (auto-increments patch version, outputs AltTabSucks-firefox.xpi):
.\dev-scripts\package-firefox-extension.ps1 -Sign
```

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
