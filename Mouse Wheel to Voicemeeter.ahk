#Requires AutoHotkey v2.0
; Mouse Wheel to Voicemeeter
; version 2.0
; by Melo (melo@meloprofessional.com)
; 
; Credits to:
; VMR AHK https://github.com/SaifAqqad/VMR.ahk
; trismarck code from here: https://www.autohotkey.com/board/topic/96139-detect-screen-edges-two-monitors/

Appname := "Mouse Wheel to Voicemeeter"
Version := 2.0
gainsteps1 := 3
gainsteps2 := 12

MacroButtonMuteUnmuteVirtualInput := Map()
; CUSTOMIZATION START - Set your macro mute button IDs as shown in the Macro Buttons UI

MacroButtonMuteUnmuteVirtualInput[1] := 23
MacroButtonMuteUnmuteVirtualInput[2] := 30
MacroButtonMuteUnmuteVirtualInput[3] := 45
; CUSTOMIZATION END

SetWorkingDir(A_ScriptDir)
#SingleInstance Force

CoordMode("Mouse", "Screen")

monCount := MonitorGetCount()
mon := Map()
Loop monCount {
    MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
    mon[A_Index] := {Left: Left, Top: Top, Right: Right, Bottom: Bottom}
}

TraySetIcon(A_ScriptDir "\mwvm.ico")
A_IconTip := "Initializing..."
Tray := A_TrayMenu
Tray.Delete()

; === MENU FUNCTIONS ===
opener(*) {
    Tray.Show()
}
Voice_Meeter(*) {
    voicemeeter.command.show()
}
Voice_Meeter_Restart(*) {
    voicemeeter.command.restart()
}
Macro_Buttons(*) {
    voicemeeter.macrobutton.Show()
}
Sounds(*) {
    Run("control mmsys.cpl sounds")
}
Volume_Mixer(*) {
    Run("sndvol.exe")
}
BootMenu(*) {
    if (CheckStartOnBoot() != "") {
        RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", Appname)
        Tray.Uncheck("Start on Boot")
    } else {
        command := A_AhkPath '" "' A_ScriptFullPath '"'
        RegWrite("REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", Appname, command)
        Tray.Check("Start on Boot")
    }
}
Restart(*) {
    Reload
}
OpenScriptFolder(*) {
    Run('explorer.exe "' A_ScriptDir '"')
}
EditScript(*) {
    Run(A_ScriptFullPath)
}
About(*) {
    MsgBox(Appname "`nMouse Wheel to Voicemeeter`nversion " Version "`n`nControl Voicemeeter virtual input volumes using the mouse wheel over the taskbar.`n`n`n`nBy Melo`nmelo@meloprofessional.com`n© Melo. All rights reserved.", "About", "OK")
}
Exit(*) {
    ExitApp
}

; === TRAY MENU ===
Tray.Add("Voicemeeter", Voice_Meeter)
Tray.Disable("Voicemeeter")
Tray.Add("Restart Audio Engine", Voice_Meeter_Restart)
Tray.Disable("Restart Audio Engine")
Tray.Add("Macro Buttons", Macro_Buttons)
Tray.Disable("Macro Buttons")
Tray.Add()
Tray.Add("Sound Control Panel", Sounds)
Tray.Add("Windows Volume Mixer", Volume_Mixer)
Tray.Add()
Tray.Add("Start on Boot", BootMenu)
if CheckStartOnBoot()
    Tray.Check("Start on Boot")
Tray.Add("Restart Script", Restart)
Tray.Add()
InfoMenu := Menu()
InfoMenu.Add("Open Script Folder", OpenScriptFolder)
InfoMenu.Add("Edit Script", EditScript)
InfoMenu.Add("About", About)
Tray.Add("Info", InfoMenu)
Tray.Add("Exit", Exit)

Tray.Add("Status: Connecting...", opener)
Tray.Default := "Status: Connecting..."

; === LOAD AND CONNECT ===
try {
    #Include VMR.ahk
} catch as e {
    MsgBox("Error loading VMR.ahk:`n" e.Message "`n`nMake sure the file is in the same folder and up to date.", Appname, "OK IconX")
    ExitApp
}

try {
    voicemeeter := VMR().Login()
} catch as e {
    MsgBox("Failed to connect to Voicemeeter:`n" e.Message "`n`nRestart the script.", Appname, "OK IconX")
    ExitApp
}

Tray.Delete("Status: Connecting...")
A_IconTip := Appname
Tray.Enable("Voicemeeter")
Tray.Enable("Restart Audio Engine")
Tray.Enable("Macro Buttons")

vm_type_name := voicemeeter.Type.Name

Fader := Map()
switch vm_type_name {
    case "Voicemeeter":        Fader[1] := 3
    case "Voicemeeter Banana": Fader[1] := 4, Fader[2] := 5
    case "Voicemeeter Potato": Fader[1] := 6, Fader[2] := 7, Fader[3] := 8
}
Total_Faders := Fader.Count

CheckStartOnBoot() {
    try {
        return RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", Appname)
    } catch {
        return ""
    }
}

MouseIsOverTaskbar() {
    MouseGetPos(,, &Win)
    return WinExist("ahk_class Shell_TrayWnd ahk_id " Win) || WinExist("ahk_class Shell_SecondaryTrayWnd ahk_id " Win)
}

#HotIf MouseIsOverTaskbar()
WheelUp::AdjustVolume(true)
WheelDown::AdjustVolume(false)

AdjustVolume(up) {
    global gainsteps, x, y
    MouseGetPos(&x, &y)
    
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 50)
        gainsteps := gainsteps2
    else
        gainsteps := gainsteps1

    i := 1
    Loop monCount {
        if (x >= mon[A_Index].Left && x <= mon[A_Index].Right && y >= mon[A_Index].Top && y <= mon[A_Index].Bottom) {
            i := A_Index
            break
        }
    }

    total_width := mon[i].Right - mon[i].Left
    width := total_width / Total_Faders
    portion := 1
    Loop Total_Faders {
        width_start := mon[i].Left + (width * A_Index - width)
        width_end := width_start + width
        if (x >= width_start && x <= width_end) {
            portion := A_Index
            break
        }
    }

    stripnum := Fader[portion]

    if (up) {
        if MacroButtonMuteUnmuteVirtualInput.Has(portion) {
            uiButtonID := MacroButtonMuteUnmuteVirtualInput[portion]
            internalButtonID := uiButtonID + 1

            try {
                currentStatus := voicemeeter.macrobutton.GetStatus(internalButtonID, 0)
                statusInt := Round(currentStatus)

                if (statusInt = 1) {
                    voicemeeter.macrobutton.SetStatus(internalButtonID, 0.0)
                }
            } catch {
                ; Silent fail
            }
        }

        ; Always unmute the strip directly for reliability
        voicemeeter.strip[stripnum].mute := false
        voicemeeter.strip[stripnum].gain += gainsteps
    } else {
        voicemeeter.strip[stripnum].gain -= gainsteps
    }
}
#HotIf