; test-edge.ahk — Validates that AltTabSucks correctly detects and activates Microsoft Edge.
;
; PART 1 — Unit: verifies _DetectInstalledBrowsers (inlined from chromium.ahk) finds Edge,
;           and that _GetHttpsHandlerExe returns the expected exe.
;
; PART 2 — Integration: sets CHROMIUM_EXE/USERDATA to Edge, launches Edge,
;           then exercises the same window-filter and WinActivate logic that FocusTab uses,
;           confirming Edge becomes the active foreground window.
;
; NOTE — "set Windows default browser to Edge":
;   Windows 10+ protects HKCU\...\UserChoice with a per-user hash that blocks direct RegWrite.
;   This test instead configures AltTabSucks to target Edge directly via its globals, and
;   separately validates the live registry detection branch if Edge is already the system
;   default. To exercise that branch, set Edge as default manually:
;     Settings → Apps → Default apps → Web browser → Microsoft Edge
;
; Run: double-click this file in Windows Explorer (requires AutoHotkey v2 installed).
;      The script exits with code 0 on all pass/skip, 1 on any failure.

#Requires AutoHotkey v2.0
#SingleInstance Force
DetectHiddenWindows 1

; --------------------------------------------------------------------------
; Tiny test harness
; --------------------------------------------------------------------------
global _results := []
global _passed  := 0
global _failed  := 0
global _skipped := 0

_Pass(name) {
    global _results, _passed
    _results.Push("  PASS  " . name)
    _passed++
}
_Fail(name, detail := "") {
    global _results, _failed
    _results.Push("  FAIL  " . name . (detail ? "`n          " . detail : ""))
    _failed++
}
_Skip(name, reason) {
    global _results, _skipped
    _results.Push("  SKIP  " . name . "`n          " . reason)
    _skipped++
}

_ShowResultsAndExit() {
    global _results, _passed, _failed, _skipped
    summary := _passed . " passed, " . _failed . " failed, " . _skipped . " skipped"
    report  := "test-edge — " . summary . "`n`n"
    for line in _results
        report .= line . "`n"
    icon := _failed > 0 ? "Icon!" : "Iconi"
    MsgBox(report, "test-edge", icon . " T15")
    ExitApp(_failed > 0 ? 1 : 0)
}

; --------------------------------------------------------------------------
; Locate Edge on disk
; --------------------------------------------------------------------------
pf86         := EnvGet("ProgramFiles(x86)")
pf           := A_ProgramFiles
localAppData := EnvGet("LOCALAPPDATA")
edgeUserData := localAppData . "\Microsoft\Edge\User Data"

edgeExe := ""
for candidate in [pf86 . "\Microsoft\Edge\Application\msedge.exe",
                  pf   . "\Microsoft\Edge\Application\msedge.exe"] {
    if FileExist(candidate) {
        edgeExe := candidate
        break
    }
}

if edgeExe = "" {
    MsgBox("Microsoft Edge not found on this system.`nAll tests skipped.", "test-edge — SKIP", "Iconi T5")
    ExitApp(0)
}

; --------------------------------------------------------------------------
; PART 1 — Unit: _DetectInstalledBrowsers and _GetHttpsHandlerExe
; --------------------------------------------------------------------------

; Inline _DetectInstalledBrowsers from chromium.ahk.
; (Can't #Include chromium.ahk — _InitChromiumState runs at include-time.)
_ScanInstalledBrowsers() {
    lad  := EnvGet("LOCALAPPDATA")
    pfl  := A_ProgramFiles
    pf86 := EnvGet("ProgramFiles(x86)")
    apd  := EnvGet("APPDATA")
    candidates := [
        {name: "Brave",   exe: pfl  . "\BraveSoftware\Brave-Browser\Application\brave.exe",  data: lad . "\BraveSoftware\Brave-Browser\User Data"},
        {name: "Chrome",  exe: pfl  . "\Google\Chrome\Application\chrome.exe",               data: lad . "\Google\Chrome\User Data"},
        {name: "Chrome",  exe: pf86 . "\Google\Chrome\Application\chrome.exe",               data: lad . "\Google\Chrome\User Data"},
        {name: "Chrome",  exe: lad  . "\Google\Chrome\Application\chrome.exe",               data: lad . "\Google\Chrome\User Data"},
        {name: "Edge",    exe: pf86 . "\Microsoft\Edge\Application\msedge.exe",              data: lad . "\Microsoft\Edge\User Data"},
        {name: "Edge",    exe: pfl  . "\Microsoft\Edge\Application\msedge.exe",              data: lad . "\Microsoft\Edge\User Data"},
        {name: "Vivaldi", exe: lad  . "\Vivaldi\Application\vivaldi.exe",                    data: lad . "\Vivaldi\User Data"},
        {name: "Opera",   exe: lad  . "\Programs\Opera\opera.exe",                           data: apd . "\Opera Software\Opera Stable"},
    ]
    result := []
    seen   := Map()
    for c in candidates {
        key := StrLower(c.exe)
        if FileExist(c.exe) && !seen.Has(key) {
            seen[key] := true
            result.Push({name: c.name, exe: c.exe, data: c.data})
        }
    }
    return result
}

installed  := _ScanInstalledBrowsers()
edgeInList := false
for b in installed {
    if !InStr(b.exe, "msedge.exe")
        continue
    edgeInList := true
    if b.name = "Edge"
        _Pass("_DetectInstalledBrowsers finds Edge: name='" . b.name . "' exe=" . b.exe)
    else
        _Fail("_DetectInstalledBrowsers: Edge exe found but name='" . b.name . "'")
    if InStr(b.data, "Microsoft\Edge\User Data")
        _Pass("_DetectInstalledBrowsers: Edge User Data path correct")
    else
        _Fail("_DetectInstalledBrowsers: Edge User Data path wrong", b.data)
    break
}
if !edgeInList
    _Fail("_DetectInstalledBrowsers: Edge not found in installed list")

; Inline _GetHttpsHandlerExe — surfaces which exe is the current https handler.
httpsHandlerExe := ""
try {
    hklmCmd := RegRead("HKLM\SOFTWARE\Classes\https\shell\open\command")
    if RegExMatch(hklmCmd, 'i)"([^"]+\.exe)"', &hm)
        httpsHandlerExe := hm[1]
    else if RegExMatch(hklmCmd, 'i)([^\s"]+\.exe)', &hm)
        httpsHandlerExe := hm[1]
}
if httpsHandlerExe != "" {
    if InStr(httpsHandlerExe, "msedge.exe")
        _Pass("_GetHttpsHandlerExe: HKLM https handler is Edge (" . httpsHandlerExe . ")")
    else
        _Skip("_GetHttpsHandlerExe: https handler is Edge",
              "HKLM handler is " . httpsHandlerExe . " — Edge will not be marked ★ in dialog")
} else {
    _Skip("_GetHttpsHandlerExe", "HKLM https command key absent or unparseable")
}

; --------------------------------------------------------------------------
; PART 2 — Integration: launch Edge and exercise FocusTab's window logic
; --------------------------------------------------------------------------
; Point AltTabSucks globals at Edge (this is what _AutoConfigIfNeeded does at runtime
; when Edge is the system default, and what config.ahk would contain for an Edge user).
global CHROMIUM_EXE      := edgeExe
global CHROMIUM_USERDATA := edgeUserData
SplitPath(edgeExe, &edgeExeName)   ; "msedge.exe"

testWindowHwnd := 0

; Remember which Edge windows exist BEFORE we launch, so we can close only ours.
winFilter    := "ahk_class Chrome_WidgetWin_1 ahk_exe " . edgeExeName
preExisting  := Map()
for hwnd in WinGetList(winFilter)
    preExisting[hwnd] := true

; Launch Edge with a neutral page in a new window.
edgePid := 0
try {
    Run('"' . edgeExe . '" --new-window "https://example.com" --no-first-run --no-default-browser-check',
        , , &edgePid)
} catch as e {
    _Fail("Launch Edge for integration test", e.Message)
    _ShowResultsAndExit()
}

; Wait up to 7s for a new Edge window to appear.
deadline := A_TickCount + 7000
Loop {
    for hwnd in WinGetList(winFilter) {
        if !preExisting.Has(hwnd) {
            testWindowHwnd := hwnd
            break 2
        }
    }
    if A_TickCount > deadline
        break
    Sleep(250)
}

if testWindowHwnd {
    _Pass("Edge window appeared after launch (hwnd=" . testWindowHwnd . ")")
} else {
    _Fail("Edge window did not appear within 7s")
    _CleanupEdge(edgePid, winFilter, preExisting)
    _ShowResultsAndExit()
}

; Give Edge a moment to settle before we try to activate it.
Sleep(800)

; --- Mirror FocusTab's visible-unowned window enumeration ---
; FocusTab builds its candidate list by filtering Chrome_WidgetWin_1 windows for
; WS_VISIBLE, no GW_OWNER, and non-empty title. Verify our test window passes the filter.
visibleUnowned := []
for hwnd in WinGetList(winFilter) {
    if !(WinGetStyle("ahk_id " hwnd) & 0x10000000)   ; WS_VISIBLE
        continue
    if DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr")  ; GW_OWNER
        continue
    if WinGetTitle("ahk_id " hwnd) = ""
        continue
    visibleUnowned.Push(hwnd)
}

testWindowInList := false
for hwnd in visibleUnowned
    if hwnd = testWindowHwnd
        testWindowInList := true

if visibleUnowned.Length > 0
    _Pass("FocusTab window filter finds " . visibleUnowned.Length . " visible Edge window(s)")
else
    _Fail("FocusTab window filter found no Edge windows")

if testWindowInList
    _Pass("Test window passes the FocusTab visible-unowned-titled filter")
else
    _Fail("Test window did NOT pass the FocusTab window filter")

; --- Mirror FocusTab's pre-HTTP focus steal and WinActivate ---
; FocusTab calls WinActivate on a browser window before making HTTP requests,
; then again after the extension responds. We validate both activations here.

; Simulate "arrived from outside browser" focus steal (first WinActivate in FocusTab).
WinActivate("ahk_id " testWindowHwnd)
Sleep(400)

activeHwnd     := WinExist("A")
activeExeName  := (activeHwnd ? WinGetProcessName("ahk_id " activeHwnd) : "")

if activeExeName = edgeExeName
    _Pass("WinActivate (pre-HTTP focus steal) brought Edge to foreground")
else
    _Fail("WinActivate did not bring Edge to foreground",
          "active process is '" . activeExeName . "', expected '" . edgeExeName . "'")

; Simulate the post-extension WinActivate (second activation, mirrors FocusTab's
; _WaitChromiumActiveAndToast polling until a Chromium window is active).
WinActivate("ahk_id " testWindowHwnd)
Sleep(300)

stillActive := WinActive("ahk_class Chrome_WidgetWin_1 ahk_exe " . edgeExeName)
if stillActive
    _Pass("Edge window remains active after second WinActivate (mirrors _WaitChromiumActiveAndToast success condition)")
else
    _Fail("Edge window is no longer active after second WinActivate")

; --- Verify window title contains expected content ---
edgeTitle := WinGetTitle("ahk_id " testWindowHwnd)
if edgeTitle != ""
    _Pass("Edge window has non-empty title: '" . edgeTitle . "'")
else
    _Fail("Edge window title is empty after activation")

; --------------------------------------------------------------------------
; Cleanup: close only the window we opened
; --------------------------------------------------------------------------
_CleanupEdge(edgePid, winFilter, preExisting)

; --------------------------------------------------------------------------
; Report
; --------------------------------------------------------------------------
_ShowResultsAndExit()

; --------------------------------------------------------------------------
; Helper: close only the Edge window(s) this test opened
; --------------------------------------------------------------------------
_CleanupEdge(pid, filter, existingHwnds) {
    Sleep(200)
    for hwnd in WinGetList(filter) {
        if !existingHwnds.Has(hwnd)
            WinClose("ahk_id " hwnd)
    }
    Sleep(500)
    ; If any test windows are still alive, kill the process.
    for hwnd in WinGetList(filter) {
        if !existingHwnds.Has(hwnd) {
            try ProcessClose(pid)
            break
        }
    }
}
