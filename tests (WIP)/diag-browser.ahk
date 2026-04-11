; diag-browser.ahk — Shows exactly what the registry says about the default browser.
; Intentionally does NOT self-elevate so you can compare the elevated vs non-elevated view.
;
; Run this TWICE:
;   1. Double-click normally (non-elevated)
;   2. Right-click → "Run as administrator" (elevated)
; If the ProgId differs between runs, elevation is changing the registry view.

#Requires AutoHotkey v2.0
#SingleInstance Force

httpsProgId  := "(read failed)"
httpProgId   := "(read failed)"
httpsCmd     := "(read failed)"
httpsCmdHklm := "(read failed)"
try httpsProgId  := RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice", "ProgId")
try httpProgId   := RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice",  "ProgId")
try httpsCmd     := RegRead("HKCU\Software\Classes\https\shell\open\command")
try httpsCmdHklm := RegRead("HKLM\SOFTWARE\Classes\https\shell\open\command")

msg := "Is admin:              " . (A_IsAdmin ? "YES (elevated)" : "no (normal)") . "`n"
     . "AHK bitness:           " . (A_PtrSize = 8 ? "64-bit" : "32-bit") . "`n"
     . "`n"
     . "=== UserChoice (what AltTabSucks reads) ===`n"
     . "https ProgId:          " . httpsProgId . "`n"
     . "http  ProgId:          " . httpProgId  . "`n"
     . "`n"
     . "=== Registered handler (what actually opens the URL) ===`n"
     . "HKCU https command:    " . httpsCmd     . "`n"
     . "HKLM https command:    " . httpsCmdHklm . "`n"
     . "`n"
     . "Expected for Edge:  MSEdgeHTM / msedge.exe`n"
     . "Expected for Brave: BraveHTML / brave.exe"

MsgBox(msg, "Browser registry diagnostic", "Iconi")
