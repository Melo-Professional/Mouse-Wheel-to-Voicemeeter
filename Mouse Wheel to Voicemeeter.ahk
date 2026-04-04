;@region Description
/************************************************************************
 * @description Control Voicemeeter virtual input volumes using the mouse wheel over the taskbar.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/04/03
 * @version 3.0
 * @github https://github.com/Melo-Professional/Mouse-Wheel-to-Voicemeeter
 * @credits VMR AHK https://github.com/SaifAqqad/VMR.ahk
 * @credits trismarck code from here: https://www.autohotkey.com/board/topic/96139-detect-screen-edges-two-monitors/
 ***********************************************************************/
;@endregion

Appname := "Mouse Wheel to Voicemeeter"
Version := 3.0
#Requires AutoHotkey v2.0
SetWorkingDir(A_ScriptDir)
#SingleInstance Force
#Include VMR.ahk
CoordMode("Mouse", "Screen")

;@Ahk2Exe-SetName Mouse Wheel to Voicemeeter
;@Ahk2Exe-SetFileVersion 3.0
;@Ahk2Exe-SetCopyright © Melo. All rights reserved.
;@Ahk2Exe-UpdateManifest 1

;@region Configuration
OSDTimeOut := 2000 ; duration of OSD in milliseconds
OSDBottomDistance := 70 ; OSD distance from bottom
gainStepsSlow := 3 ; dbs to change when scrolling slow
gainStepsFast := 12 ; dbs to change when scrolling fast

; Define the Logical IDs of MacroButtons used to mute/unmute each VoiceMeeter strip.
; IMPORTANT: The order MUST be:
; [1] VoiceMeeter Input
; [2] VoiceMeeter AUX
; [3] VoiceMeeter VAIO3
MacroButtonMuteUnmuteVirtualInput := [
    23, ; [1] VoiceMeeter Input strip
    30, ; [2] VoiceMeeter AUX strip
    45  ; [3] VoiceMeeter VAIO3 strip
]
;@endregion

;@region Menu
TraySetIcon(A_ScriptDir "\mwvm.ico")
A_IconTip := "Initializing..."
Tray := A_TrayMenu
Tray.Delete()

; === MENU FUNCTIONS ===
opener(*) => Tray.Show()
Voice_Meeter(*) => voicemeeter.command.show()
Voice_Meeter_Restart(*) => voicemeeter.command.restart()
Macro_Buttons(*) => voicemeeter.macrobutton.Show()
Sounds(*) => Run("control mmsys.cpl sounds")
Volume_Mixer(*) => Run("sndvol.exe")
BootMenu(*) {
    if (CheckStartOnBoot() != "") {
        try {
            RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", Appname)
        } catch as e {
            MsgBox("Failed to remove start on boot entry:`n" e.Message, Appname, "OK Icon!")
            return
        }
        Tray.Uncheck("Start on Boot")
    } else {
        command := '"' A_AhkPath '" "' A_ScriptFullPath '"'
        try {
            RegWrite command, "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", Appname
        } catch as e {
            MsgBox("Failed to add start on boot entry:`n" e.Message, Appname, "OK Icon!")
            return
        }
        Tray.Check("Start on Boot")
    }
}
Restart(*) {
    Reload
}
OpenScriptFolder(*) => Run('explorer.exe "' A_ScriptDir '"')
EditScript(*) => Run(A_ScriptFullPath)
About(*) {
    MsgBox(
            Appname "`n"
            "version " Format("{:.1f}", Version) "`n`n"
            "Control Voicemeeter virtual input volumes using the mouse wheel over the taskbar.`n`n`n`n"
            "By Melo`nmelo@meloprofessional.com`n"
            "©Melo. All rights reserved.", 
            "About", "OK")
}
Repo(*) {
    Run("https://github.com/Melo-Professional/Mouse-Wheel-to-Voicemeeter")
}
Exit(*) {
    ExitApp
}
CheckStartOnBoot() {
    try {
        return RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", Appname)
    } catch {
        return ""  ; Return empty string if key/value doesn't exist or error
    }
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
InfoMenu.Add("GitHub Repo", Repo)
Tray.Add("Info", InfoMenu)
Tray.Add("Exit", Exit)
Tray.Add("Status: Connecting...", opener)
Tray.Default := "Status: Connecting..."
LoginVMR()
Tray.Delete("Status: Connecting...")
A_IconTip := Appname
Tray.Enable("Voicemeeter")
Tray.Enable("Restart Audio Engine")
Tray.Enable("Macro Buttons")
;@endregion

;@region Login VMR
LoginVMR() {
; === CONNECT VMR ===
	try {
		Global voicemeeter
	    voicemeeter := VMR().Login()
	} catch as e {
	    MsgBox("Failed to connect to Voicemeeter:`n" e.Message "`n`nRestart the script.", Appname, "OK IconX")
	    ExitApp
	}
}
vm_type_name := voicemeeter.Type.Name
;@endregion

;@region OSD Start
global osdGui := ""
global osdTextCtrl := ""

CreateVolumeOSD() {
    global osdGui, osdTextCtrl

    osdGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20 -DPIScale", "VMR_VolumeOSD")
    osdGui.BackColor := "2E2E2E"
    osdGui.MarginX := 20
    osdGui.MarginY := 18
    osdGui.SetFont("s12 cFFFFFF w700 q5", "Segoe UI")
    osdTextCtrl := osdGui.Add("Text", "Center w160", "Strip Name: 100%")
    osdGui.Show("Hide")

    WinSetTransparent(210, osdGui.Hwnd)
    ApplyRoundedCorners()
}

ApplyRoundedCorners() {
    global osdGui

    if (!IsObject(osdGui))
        return

    osdGui.GetClientPos(,, &w, &h)
    if (w > 0 && h > 0) {
        WinSetRegion("0-0 w" w " h" h " r40-40", osdGui.Hwnd)
    }
}

CreateVolumeOSD()
;@endregion

;@region Faders Enumeration
Fader := []
switch vm_type_name {
    case "Voicemeeter":     Fader := [3]
    case "Voicemeeter Banana": Fader := [4, 5]
    case "Voicemeeter Potato": Fader := [6, 7, 8]
}
Total_Faders := Fader.Length
;@endregion

;@region Monitor Enumeration
monCount := MonitorGetCount()
mon := []
Loop monCount {
    MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
    mon.Push({Left: Left, Top: Top, Right: Right, Bottom: Bottom})
}
;@endregion

;@region Main Logic
MouseIsOverTaskbar() {
    MouseGetPos(,, &Win)
    return WinExist("ahk_class Shell_TrayWnd ahk_id " Win) 
        || WinExist("ahk_class Shell_SecondaryTrayWnd ahk_id " Win)
}

#HotIf MouseIsOverTaskbar()
WheelUp::   AdjustVolume(true)
WheelDown:: AdjustVolume(false)
#HotIf

AdjustVolume(up) {
    global gainsteps, x, y

    MouseGetPos(&x, &y)

    ; Fast scroll
    if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 50)
        gainsteps := gainStepsFast
    else
        gainsteps := gainStepsSlow

    ; Find current monitor
    currentMonitorIndex := 1
    Loop monCount {
        if (x >= mon[A_Index].Left && x <= mon[A_Index].Right
            && y >= mon[A_Index].Top && y <= mon[A_Index].Bottom) {
            currentMonitorIndex := A_Index
            break
        }
    }

    ; Find strip index
    portion := Floor((x - mon[currentMonitorIndex].Left) 
              / (mon[currentMonitorIndex].Right - mon[currentMonitorIndex].Left) 
              * Total_Faders) + 1
    portion := Min(portion, Total_Faders)

    stripnum := Fader[portion]

    ; === Call VoiceMeeter ===
    if (up) {
        if MacroButtonMuteUnmuteVirtualInput.Has(portion) {
            uiButtonID := MacroButtonMuteUnmuteVirtualInput[portion]
            internalButtonID := uiButtonID + 1
            try {
                if (Round(voicemeeter.macrobutton.GetStatus(internalButtonID, 0)) = 1)
                    voicemeeter.macrobutton.SetStatus(internalButtonID, 0.0)
            }
        }
        voicemeeter.strip[stripnum].mute := false
        voicemeeter.strip[stripnum].gain += gainsteps
    } else {
        voicemeeter.strip[stripnum].gain -= gainsteps
    }

    showStripInfo(stripnum)
}
;@endregion

;@region OSD Show
showStripInfo(stripnum) {
    global osdGui, osdTextCtrl
    static lastStrip := 0
    static lastPercent := -1
    strip := voicemeeter.Strip[stripnum]
    label := strip["Label"]
    stripName := (label != "") ? label : strip.Name

    db := strip.gain
    percent := (db + 60) / 72 * 100
    percent := Round(Max(0, Min(100, percent)), 0)

    newText := stripName ": " percent "%"

    if (stripnum != lastStrip || percent != lastPercent) {
        osdTextCtrl.Text := newText
        lastStrip := stripnum
        lastPercent := percent
    }

    osdGui.Show("AutoSize NoActivate")
    ApplyRoundedCorners()

    osdGui.GetClientPos(,, &guiW, &guiH)
    x := (A_ScreenWidth - guiW) // 2
    y := A_ScreenHeight - guiH - OSDBottomDistance

    osdGui.Show("x" x " y" y " NoActivate")

    ; Timer to destroy OSD
    SetTimer(HideVolumeOSD, 0)
    SetTimer(HideVolumeOSD, -OSDTimeOut)
}

HideVolumeOSD(*) {
    global osdGui

    if (IsObject(osdGui))
        osdGui.Hide()
}
;@endregion
