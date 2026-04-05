; toast.ahk - Profile name overlay toast shown after Brave window/tab switches

global _activeToast  := ""
global _toastColorIdx := 0
global _toastROYGBIV  := [
    0xCC0000,  ; red
    0xE53300,  ; red-orange
    0xFF6600,  ; orange
    0xFF9900,  ; amber
    0xFFCC00,  ; yellow
    0x80B300,  ; yellow-green
    0x009900,  ; green
    0x006F66,  ; teal
    0x0044CC,  ; blue
    0x2622A7,  ; blue-indigo
    0x4B0082,  ; indigo
    0x6B00C1,  ; purple
    0x8B00FF,  ; violet
]

; Sample a pixel from the right edge of the titlebar to match the toast background
; to the window's current theme color.
SampleTitlebarColor(hwnd) {
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    hDC := DllCall("GetDC", "Ptr", 0)
    pixel := DllCall("GetPixel", "Ptr", hDC, "Int", wx + ww - ww // 10, "Int", wy + 10)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
    r := pixel & 0xFF
    g := (pixel >> 8) & 0xFF
    b := (pixel >> 16) & 0xFF
    return Format("{:02X}{:02X}{:02X}", r, g, b)
}

_ExpireToast(t, capturedPtr) {
    global _activeToast
    try t.Destroy()
    if ObjPtr(_activeToast) = capturedPtr
        _activeToast := ""
}

; Centered screen toast for first-launch browser auto-detection notification.
ShowSetupToast(browserName, exePath, userDataPath, duration := 5000) {
    t := Gui("-Caption +ToolWindow +AlwaysOnTop")
    t.BackColor := "1A2A3A"
    t.SetFont("s12 bold cFFFFFF", "Consolas")
    t.Add("Text", "x18 y14", "AltTabSucks: browser auto-detected")
    t.SetFont("s11 bold c7EC8E3", "Consolas")
    t.Add("Text", "x18 y40", browserName)
    t.SetFont("s9 cAABBCC", "Consolas")
    t.Add("Text", "x18 y62", exePath)
    t.Add("Text", "x18 y80", userDataPath)
    t.SetFont("s8 c556677", "Consolas")
    t.Add("Text", "x18 y102 w400", "config.ahk written  —  edit to change")
    t.Show("Hide NoActivate")
    WinGetPos(, , &tw, &th, "ahk_id " t.Hwnd)
    tw += 18  ; right padding
    th += 14
    WinSetRegion("R14-14 0-0 w" tw " h" th, "ahk_id " t.Hwnd)
    t.Show("NoActivate x" (A_ScreenWidth - tw) // 2 " y" (A_ScreenHeight - th) // 2)
    SetTimer(() => t.Destroy(), -duration)
}

ShowProfileToast(hwnd, label, bgColor) {
    global _activeToast, _toastColorIdx, _toastROYGBIV
    ; If a toast is already on screen, cycle to the next ROYGBIV color
    ; (let the old toast's own timer destroy it to avoid double-destroy)
    if IsObject(_activeToast) {
        _toastColorIdx := Mod(_toastColorIdx, _toastROYGBIV.Length) + 1
        bgColor := _toastROYGBIV[_toastColorIdx]
    }
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
    t := Gui("-Caption +ToolWindow +AlwaysOnTop")
    t.BackColor := bgColor
    t.SetFont("s24 bold c471313", "Consolas")
    t.Add("Text", "x34 y27", StrUpper(label))
    t.SetFont("s24 bold cWhite", "Consolas")
    t.Add("Text", "x30 y23 BackgroundTrans", StrUpper(label))
    t.Show("Hide")
    WinGetPos(&_tx, &_ty, &tw, &th, "ahk_id " t.Hwnd)
    WinSetRegion("R20-20 0-0 w" tw " h" th, "ahk_id " t.Hwnd)
    t.Show("NoActivate x" (wx + (ww - tw) // 2) " y" (wy + (wh - th) // 2))
    _activeToast := t
    local capturedPtr := ObjPtr(t)
    SetTimer(() => _ExpireToast(t, capturedPtr), -250)
}
