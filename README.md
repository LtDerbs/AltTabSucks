# AltTabSucks

AutoHotkey v2 automation scripts for Windows productivity — window cycling, Chromium browser profile switching, and profile-aware tab control via a local HTTP bridge. Works with any Chromium-based browser (Brave, Chrome, Edge, Vivaldi).

## Components

| Path | Purpose |
|---|---|
| `AltTabSucks.ahk` | Entry point — self-elevates and includes all libs |
| `lib/utils.ahk` | Window management (`ManageAppWindows`, `ShowTextGui`) |
| `lib/config.ahk` | Machine-local config: `CHROMIUM_EXE`, `CHROMIUM_USERDATA` (**gitignored**, see `config.template.ahk`) |
| `lib/config.template.ahk` | Sanitized config template, tracked in git |
| `lib/chromium.ahk` | Chromium profile cycling + tab focus via AltTabSucks |
| `lib/toast.ahk` | Visual feedback overlays |
| `lib/star-citizen.ahk` | Star Citizen–scoped hotkeys |
| `lib/app-hotkeys.ahk` | General app/browser hotkeys (**gitignored** — contains real paths) |
| `lib/app-hotkeys.template.ahk` | Sanitized version of above, tracked in git |
| `BrowserExtension/` | AltTabSucks: PowerShell HTTP server + Chromium extension |
| `startServer.ps1` | Manually start the AltTabSucks server |
| `screenOff.ps1` | Turn off monitor |
| `make-template.sh` | Regenerate the sanitized hotkeys template |

## Quick Start

### 1. Run the AHK script

Double-click `AltTabSucks.ahk` in Windows Explorer. It self-elevates to admin.

- **Reload**: `Ctrl+Alt+Shift+'`
- **Debug**: Right-click tray icon → Window Spy

### 2. Configure your browser

Copy `lib/config.template.ahk` to `lib/config.ahk` and fill in the paths for your Chromium-based browser:

```ahk
global CHROMIUM_EXE      := "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
global CHROMIUM_USERDATA := "C:\Users\YourName\AppData\Local\BraveSoftware\Brave-Browser\User Data"
```

### 3. Set up AltTabSucks (browser tab bridge)

See [`BrowserExtension/README.md`](BrowserExtension/README.md) for full setup. Short version:

```powershell
# Registers a Task Scheduler task that auto-starts at logon (will prompt UAC)
powershell -ExecutionPolicy Bypass -File ".\BrowserExtension\install-service.ps1"

# Verify
curl http://localhost:9876/tabs
```

Then load the extension in your browser's extensions page (e.g. `brave://extensions`, `chrome://extensions`) → Developer mode → Load unpacked → `BrowserExtension/` → set your profile name in Options.

## Hotkey Conventions

| Modifier | Meaning |
|---|---|
| `^` | Ctrl |
| `!` | Alt |
| `+` | Shift |
| `#` | Win |
| `~` | Pass-through |

General hotkeys use `Ctrl+Alt+Shift+<key>`. App-scoped hotkeys are wrapped in `#HotIf WinActive(...)`.

## Adding Hotkeys

Add new hotkeys to `lib/app-hotkeys.ahk` (gitignored). Before committing:

```bash
./make-template.sh   # redacts URLs/paths/profiles → lib/app-hotkeys.template.ahk and lib/config.template.ahk
```

Commit only `app-hotkeys.template.ahk` and `config.template.ahk`.

## Requirements

- Windows with [AutoHotkey v2](https://www.autohotkey.com/)
- PowerShell 5+ (for AltTabSucks server)
- A Chromium-based browser (Brave, Chrome, Edge, Vivaldi) for tab-switching features
