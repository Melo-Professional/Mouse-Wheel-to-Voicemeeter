#Requires AutoHotkey v2.0

MouseIsOverTaskbar() {
    MouseGetPos(,, &Win)
    OldMatchMode := SetTitleMatchMode("RegEx")
    IsOver := WinExist("ahk_class ^Shell_(Secondary)?TrayWnd$ ahk_id " Win)
    SetTitleMatchMode(OldMatchMode)
    return IsOver
}

RestartAll(){
    ; 1. Restart the Voicemeeter Audio Engine
    voicemeeter.Command.Restart()
    
    ; 2. Handle MacroButtons Restart using the Process Path
    if (mbPID := ProcessExist("VoicemeeterMacroButtons.exe")) {
        try {
            ; Get the full path of the running executable
            mbPath := ProcessGetPath(mbPID)

            ; Close the process
            ProcessClose(mbPID)
            ProcessWaitClose(mbPID, 2)
            
            ; Run it again using the exact path we just found
            Run(mbPath)
        } catch {
            ; If for some reason we can't get the path, just close it
            ProcessClose("VoicemeeterMacroButtons.exe")
        }
    }
    ; 3. Restart Script
    Reload()
}