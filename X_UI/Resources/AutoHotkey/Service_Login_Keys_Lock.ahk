; Log start time
FormatTime, StartTime,, yyyy-MM-dd HH:mm:ss
FileAppend, % "Script started at " StartTime "`n", C:\XACT_UI\Logs\HotKeysLogs.log

; Disable hotkeys
#IfWinActive ; Only disable keys when a window is active
{
    *LWin::Return
    *RWin::Return
    *Alt::Return
    *LControl::Return
    *RControl::Return
    *F1::Return
    *F2::Return
    *F3::Return
    *F4::Return
    *F5::Return
    *F6::Return
    *F7::Return
    *F8::Return
    *F9::Return
    *F10::Return
    *F11::Return
    *F12::Return
    *Insert::Return
    *Home::Return
    *PgUp::Return
    *PgDn::Return
    *End::Return
    *Delete::Return
    *ScrollLock::Return
    *Pause::Return
    *Esc::Return
    *Left::Return
    *Right::Return
    *Up::Return
    *Down::Return
    ^!Delete::Return
    !Tab::Return
    !Shift::Return
    !F4::Return
    #r::Return
}

; Log end time
OnExit, LogExit
return

LogExit:
FormatTime, EndTime,, yyyy-MM-dd HH:mm:ss
FileAppend, % "Script ended at " EndTime "`n", C:\XACT_UI\Logs\HotKeysLogs.log
