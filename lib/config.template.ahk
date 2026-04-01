; config.ahk - Machine-local configuration (copy to config.ahk and fill in your paths)
; This file is tracked in git with placeholders. config.ahk is gitignored.

; Full path to the Chromium-based browser executable you want to use.
; Use A_ProgramFiles for Program Files, or EnvGet("LOCALAPPDATA") for per-user installs.
; Examples:
;   Brave:   A_ProgramFiles . "C:\YOUR\PATH"
;   Chrome:  A_ProgramFiles . "C:\YOUR\PATH"
;   Edge:    EnvGet("ProgramFiles(x86)") . "C:\YOUR\PATH"
;   Vivaldi: EnvGet("LOCALAPPDATA") . "C:\YOUR\PATH"
global CHROMIUM_EXE      := A_ProgramFiles . "C:\YOUR\PATH"

; Full path to the browser's User Data directory (contains Local State and profile folders).
; Examples:
;   Brave:   EnvGet("LOCALAPPDATA") . "C:\YOUR\PATH"
;   Chrome:  EnvGet("LOCALAPPDATA") . "C:\YOUR\PATH"
;   Edge:    EnvGet("LOCALAPPDATA") . "C:\YOUR\PATH"
;   Vivaldi: EnvGet("LOCALAPPDATA") . "C:\YOUR\PATH"
global CHROMIUM_USERDATA := EnvGet("LOCALAPPDATA") . "C:\YOUR\PATH"
