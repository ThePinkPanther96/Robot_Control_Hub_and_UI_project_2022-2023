; Log start time
FormatTime, StartTime,, yyyy-MM-dd HH:mm:ss
FileAppend, % "Script started at " StartTime "`n", C:\XACT_UI\Logs\HotKeysLogs.log

; Disable hotkeys
!F4::Return
!Tab::Return
F1::Return
F2::Return
F3::Return
F4::Return
F5::Return
F6::Return
F7::Return
F8::Return
F9::Return
F10::Return
F11::Return
F12::Return

; Log end time
OnExit, LogExit
return

LogExit:
  FormatTime, EndTime,, yyyy-MM-dd HH:mm:ss
  FileAppend, % "Script ended at " EndTime "`n", C:\XACT_UI\Logs\HotKeysLogs.log
