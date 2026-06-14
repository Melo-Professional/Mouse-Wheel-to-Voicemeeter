/************************************************************************
 * @description App Functions
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/24
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0
LoginVMR() {
    Global voicemeeter

    ; Disable some Tray items
    TrayMenu                := A_TrayMenu
;    TrayMenu.Rename("Mouse Wheel to VM", "Connecting to Voicemeeter")
    TrayMenu.Disable("Voicemeeter")
    TrayMenu.Disable("Restart Audio Engine")
    TrayMenu.Disable("Macro Buttons")
    TrayMenu.Disable("Restart All")

    timeout := 20000 ; Total time to keep trying
    startTime := A_TickCount
    
    while (A_TickCount - startTime < timeout) {
        try {
            voicemeeter := VMR().Login()

            ; Re enable tray items
            TrayMenu.Rename("Connecting to Voicemeeter", "Mouse Wheel to VM")
            TrayMenu.Enable("Voicemeeter")
            TrayMenu.Enable("Restart Audio Engine")
            TrayMenu.Enable("Macro Buttons")
            TrayMenu.Enable("Restart All")
            return ; Success! Exit the function
        } catch as err {
            Sleep(500) ; Wait 0.5s before the next attempt
        }
    }

    ; Timeout expired without a successful login
    SplashScreen()
    if (MsgBoxCustom("Failed to connect to Voicemeeter.", App.Name " Error", "RetryCancel", err) = "Retry") {
        Reload()
    }
    ExitApp()
}

GetFaders(){
    ;global Faders, Total_Faders

    current := []
    switch voicemeeter.Type.Name {
        case "Voicemeeter":     current := [3]
        case "Voicemeeter Banana": current := [4, 5]
        case "Voicemeeter Potato": current := [6, 7, 8]
    }
;    Total_Faders := Faders.Length
    return current
}

ListenAndLastGainValues() {
    global LastGainValues
    LastGainValues := Map()
    voicemeeter.Off("ParametersChanged")
    for index, stripIdx in Faders {
        LastGainValues[stripIdx] := voicemeeter.Strip[stripIdx].Gain
        if (OSDSettings.UseOSD && (!A_IsSuspended)) {
            voicemeeter.On("ParametersChanged", CheckVolumeChange.Bind(stripIdx))
        }
    }
}

MouseIsOverTaskbar(&targetWin := 0, &mx := 0, &my := 0) {
    MouseGetPos(&mx, &my, &hWnd)

    winClass := WinGetClass(hWnd)

    if (winClass != "Shell_TrayWnd"
     && winClass != "Shell_SecondaryTrayWnd")
        return false

    targetWin := hWnd
    return true
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