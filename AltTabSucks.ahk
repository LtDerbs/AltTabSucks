; Copyright (C) 2026 LtDerbs
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version. See LICENSE for details.

#Requires AutoHotkey v2.0
#SingleInstance Force
DetectHiddenWindows 1
if not A_IsAdmin
    Run '*RunAs "' A_ScriptFullPath '"'

^!+':: Reload  ; reload script

#Include lib\utils.ahk        ; ShowTextGui, ManageAppWindows
#Include lib\toast.ahk        ; SampleTitlebarColor, ShowProfileToast
#Include lib\config.ahk       ; CHROMIUM_EXE, CHROMIUM_USERDATA (gitignored, see config.template.ahk)
#Include lib\chromium.ahk     ; Chromium profile cycling + tab focus via AltTabSucks server
#Include lib\app-hotkeys.ahk  ; general app + browser hotkeys
#Include lib\star-citizen.ahk ; Star Citizen automation (scoped to SC window)
