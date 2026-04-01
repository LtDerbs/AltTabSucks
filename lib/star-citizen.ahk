; star-citizen.ahk - Star Citizen automation hotkeys (active only when SC has focus)

_starCitizenAppTitle := "Star Citizen"

SingleBeep(b) {
    SoundBeep(b, 75)
}
DoubleBeep(b) {
    SoundBeep(b, 75)
    SoundBeep(b, 100)
}

#HotIf WinActive(_starCitizenAppTitle)

; Auto run forward (Shift+Alt+W) - also works with ship but uses boost
+!w Up:: {
    SingleBeep(1050)
    loop {
        Send("{w down}")
        Send("{LShift down}")
    } until KeyWait("w", "DT0.1")
    Send("{w up}")
    Send("{LShift up}")
    DoubleBeep(1050)
}

Global W_Pressed_Flag := false

~w:: {
    Global W_Pressed_Flag
    W_Pressed_Flag := true
}

; Random looking - pretend to look around while walking/flying (Alt+S)
!s up:: {
    SingleBeep(600)
    Send("{f4}")
    Global W_Pressed_Flag
    W_Pressed_Flag := false
    Loop {
        Send("{z down}")
        Sleep 50
        mousemove(Random(1, 100), Random(1, 100), Random(50, 100), "R")
        Sleep 50
        Send("{z up}")
        Sleep 10000
        if (W_Pressed_Flag)
            Break
    }
    DoubleBeep(1050)
}

; Auto scan - double-tap Tab to start, Tab again to stop
~Tab Up:: {
    if (KeyWait("Tab", "DT.3")) {
        KeyWait("Tab", "T.3")
        SingleBeep(200)
        Loop {
            Send("{Tab}")
            if (KeyWait("Tab", "DT2"))
                Break
        }
        DoubleBeep(200)
    }
}

; Reposition window - move fullscreen-windowed up to hide titlebar (Alt+M)
!m:: {
    WinGetPos(, , , &_windowHeight, _starCitizenAppTitle)
    WinMove(, Min(A_ScreenHeight - _windowHeight, 0),,, _starCitizenAppTitle)
}

; Move window back down (Shift+Alt+M)
+!m:: {
    WinMove(, 0,,, _starCitizenAppTitle)
}

~PrintScreen Up:: {
    DoubleBeep(2000)
}

^!+b:: DoubleBeep(700)

#HotIf  ; reset scope
