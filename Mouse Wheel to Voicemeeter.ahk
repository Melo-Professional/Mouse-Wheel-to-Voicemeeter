;@region Setup
;@region Description
/************************************************************************
 * @description Control Voicemeeter virtual Inputs volumes using the mouse wheel over the taskbar.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/18
 * @releasedate 2022/05/11
 * @version 3.57.0
 * @github https://github.com/Melo-Professional/Mouse-Wheel-to-Voicemeeter
 * @credits VMR AHK https://github.com/SaifAqqad/VMR.ahk
 * @credits trismarck code from here: https://www.autohotkey.com/board/topic/96139-detect-screen-edges-two-monitors/
 ***********************************************************************/
;@endregion

;@region Compilation
;@Ahk2Exe-SetName MouseWheeltoVoicemeeter
;@Ahk2Exe-SetFileVersion 3.57.0
;@Ahk2Exe-SetCopyright © Melo. All rights reserved.
;@Ahk2Exe-SetProductName MouseWheeltoVoicemeeter
;@Ahk2Exe-SetInternalName MouseWheeltoVoicemeeter
;@Ahk2Exe-SetCompanyName Melo Professional
;@Ahk2Exe-ExeName MouseWheeltoVoicemeeter
;@Ahk2Exe-SetMainIcon mwvm.ico
;@endregion

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
A_IconHidden := true
CoordMode("Mouse", "Screen")
;@endregion

;@region Configuration
App := {
    Name:                   "Mouse Wheel to Voicemeeter",
    Description:            "Control Voicemeeter Virtual Inputs volumes using the mouse wheel over the taskbar.",
    Icon:                   A_IsCompiled ? A_ScriptFullPath : (A_ScriptDir "\mwvm.ico"),
    Copyright:              "Developed by Melo`nmelo@meloprofessional.com`n©Melo. All rights reserved.",
    Version:                "3.57.0"
}

Settings := {
    ; General GUI
    SplashScreen:               "Banner",       ; "Icon" / "Banner" / "Disabled"
    BTDetect:                   true,           ; Restart audio engine wheneve new bluetooth connects
    WheelSpeed:                 10,
    DesiredTheme:               "Auto",         ; "Auto" / "Light" / "Dark"
    GuiFontSizeSmall:           8,
    GuiFontSizeMedium:          9,
    GuiFontSizeBig:             10,
    GuiFontSizeExtraBig:        14,
    GuiFontName:                "Segoe UI",
    GuiSplashTimer:             1200,

; GUI Colors
    Theme: {
        Dark: {
            Bg:                 "202020", 
            TextDefault:        "CCCCCC",
            TextStrong:         "FFFFFF",
            TextSmooth:         "888888" 
        },
        Light: {
            Bg:                 "F0F0F0", 
            TextDefault:        "222222",
            TextStrong:         "000000",
            TextSmooth:         "666666" 
        }
    }
}
;@endregion

;@region Vars
Debug                       := false
A_ScriptName                := App.Name
CurrentActualTheme := "Dark"

gainStepsMin := 2
gainStepsMax := 20

; Define the Logical IDs of MacroButtons used to mute/unmute each VoiceMeeter strip.
; if you dont have, put MacroButtonMuteUnmuteVirtualInput := []
; IMPORTANT: The order MUST be:
; [1] VoiceMeeter Input
; [2] VoiceMeeter AUX
; [3] VoiceMeeter VAIO3

MacroButtonMuteUnmuteVirtualInput := [
                            23, ; [1] VoiceMeeter Input strip
                            30, ; [2] VoiceMeeter AUX strip
                            45  ; [3] VoiceMeeter VAIO3 strip
]


OSDSettings := {
    UseOSD:                     true,
    Width:                      200,    ; valor correto
    FontSize:                   9,
    TimeOut:                    1800,       ; duration of OSD in milliseconds
    Speed:                      4,          ; Pixels moved per tick (Increase for faster animations)
    Position:                   "Bottom",   ; Bottom / Top
    EdgeDistance:               60,         ; OSD distance from screen edge
    SlideDistance:              23,          ; Set your preferred slide distance here
    FontName:                   "Segoe UI",
    FontWeight:                 1000,
    MarginX:                    16,
    MarginY:                    12,
    Opacity:                    255,
    ColoredBorder:              true,
    RoundedCorners:             18,
    ProgressMaxValue:           100,

    ; Theme
    Theme:                      "Auto", ; "Light" / "Dark" / "Auto"

    ; lightmode
    TextDefaultLight:           "5a5555",
    BgColorLight:               "F5F9FB",
    BorderColorLight:           "ffffff",
    ProgressFgColorLight:       "0067C0",
    ProgressBgColorLight:       "EDF1F2", ; HEX or "transparent"
    ProgressOver100Light:       "FF5555",

    ; darkmode
    TextDefaultDark:            "d8d8d8",
    BgColorDark:                "272525",
    BorderColorDark:            "272525",
    ProgressFgColorDark:        "4CC2FF",
    ProgressBgColorDark:        "333333", ; HEX or "transparent"
    ProgressOver100Dark:        "FF5555",

}
;SaveToINI := [""] ; what to save to INI file
SaveToINI := ["Settings.DesiredTheme", "Settings.SplashScreen", "Settings.BTDetect",
            "Settings.WheelSpeed", "OSDSettings.UseOSD", "OSDSettings.TimeOut",
            "OSDSettings.Width", "OSDSettings.FontSize", "OSDSettings.Position", 
            "OSDSettings.TextDefaultLight", "OSDSettings.BgColorLight", "OSDSettings.BorderColorLight",
            "OSDSettings.ProgressFgColorLight", "OSDSettings.ProgressBgColorLight", "OSDSettings.ProgressOver100Light", 
            "OSDSettings.TextDefaultDark", "OSDSettings.BgColorDark", "OSDSettings.BorderColorDark", 
            "OSDSettings.ProgressFgColorDark", "OSDSettings.ProgressBgColorDark", "OSDSettings.ProgressOver100Dark",
            "OSDSettings.Speed"
]

ResetOSDSettings    := OSDSettings.Clone()
ResetSettings       := Settings.Clone()

;@endregion

;@region Includes
#Include <Save_Settings>
#Include <Theme>
#Include <Color_Picker_Dialog>
#Include <MsgBoxCustom>
#Include <SplashScreen>
#Include <SplashIcon>
#Include <About>
#Include <Menu>
#Include <App_Funcs>
#Include <App_Options>
#Include <OSD_Options>
#Include <VMR>
#Include <OSD_Manager>
;@endregion

;@region Startup
; SPLASHSCREEN
switch Settings.SplashScreen {
    case "Icon": SplashIcon.Show()
    case "Banner": Splash.Show()
}

; TRAY ICON + MENU
StartMenu()

;@endregion
;@endregion

;@region Login VM
LoginVMR()
LoginVMR() {
    Global voicemeeter

    ; Disable some Tray items
    TrayMenu                := A_TrayMenu
    TrayMenu.Rename("Mouse Wheel to VM", "Connecting to Voicemeeter")
    TrayMenu.Disable("Voicemeeter")
    TrayMenu.Disable("Restart Audio Engine")
    TrayMenu.Disable("Macro Buttons")
    TrayMenu.Disable("Restart All")

    timeout := 10000 ; Total time to keep trying
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
    switch Settings.SplashScreen {
        case "Icon": SplashIcon.Destroy()
        case "Banner": Splash.Destroy()
    }
    if (MsgBoxCustom("Failed to connect to Voicemeeter.", App.Name " Error", "RetryCancel", err) = "Retry") {
        Reload()
    }
    ExitApp()
}
;@endregion

;@region Monitor, Faders and Current Gains
monCount := MonitorGetCount()
mon := []
Loop monCount {
    MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)
    mon.Push({Left: Left, Top: Top, Right: Right, Bottom: Bottom})
}

Faders := []
switch voicemeeter.Type.Name {
    case "Voicemeeter":     Faders := [3]
    case "Voicemeeter Banana": Faders := [4, 5]
    case "Voicemeeter Potato": Faders := [6, 7, 8]
}
Total_Faders := Faders.Length

ListenAndLastGainValues()
ListenAndLastGainValues() {
    global LastGainValues

    LastGainValues := Map()
    for index, stripIdx in Faders {
        LastGainValues[stripIdx] := voicemeeter.Strip[stripIdx].Gain
        if OSDSettings.UseOSD
            voicemeeter.On("ParametersChanged", CheckVolumeChange.Bind(stripIdx))
        else
            voicemeeter.Off("ParametersChanged", CheckVolumeChange.Bind(stripIdx))
    }
}
;@endregion

switch Settings.SplashScreen {
    case "Icon": SplashIcon.Destroy()
    case "Banner": Splash.Destroy()
}

;@region OSD
OSDUpdateColors()
CreateOSD()

;@endregion

ready := true

;@region HotKeys
#HotIf MouseIsOverTaskbar() && IsSet(ready)
WheelUp:: AdjustVolume(true)
WheelDown:: AdjustVolume(false)
#HotIf


; Ctrl + ScrollLock
$^sc046:: {
    Reload()
}

; Shift + Ctrl + ScrollLock
$+^sc046:: {
    RestartAll()
}

;@endregion
;@region Mouse Wheel Logic
AdjustVolume(up) {
    global voicemeeter, mon, monCount, Faders, Total_Faders
    static lastX := -1, lastY := -1, cachedStrip := 1

    ; --- 1. Get Strip by mouse position (with cache) ---
    mousetolerance := 20 ; Minimum pixels moved before updating strip logic
    MouseGetPos(&x, &y)
    ; Only recalculate monitor/strip if the mouse has moved
    if (Abs(x - lastX) > mousetolerance || Abs(y - lastY) > mousetolerance) {
        ;ToolTip(A_TickCount)
        currentMonitorIndex := 1
        
        ; Fallback for loop count
        loopCount := IsNumber(monCount) ? monCount : 1
        
        Loop loopCount {
            if (x >= mon[A_Index].Left && x <= mon[A_Index].Right
                && y >= mon[A_Index].Top && y <= mon[A_Index].Bottom) {
                currentMonitorIndex := A_Index
                break
            }
        }

        ; Map X coordinate to the specific VoiceMeeter Strip
        m := mon[currentMonitorIndex]
        width := Max(1, m.Right - m.Left)
        portion := Min(Floor((x - m.Left) / width * Total_Faders) + 1, Total_Faders)
        cachedStrip := Faders[portion]
        ; Update position cache
        lastX := x
        lastY := y
    }
    stripnum := cachedStrip

    ; --- 1. WHEEL VELOCITY DETECTION ---


    ; Intercept A_TimeSincePriorHotkey to prevent "empty string" errors
    tsPrior := IsNumber(A_TimeSincePriorHotkey) ? A_TimeSincePriorHotkey : 300
    invertedacceleration := round(100 / Settings.WheelSpeed)

    ; If timing is invalid (-1) or too long, treat as 300ms (slow)
    timeSince := (tsPrior == -1) ? 300 : tsPrior

    if (timeSince < 100) {  ; time limit to reset velocity
        ; ACCELERATION ADJUSTMENT:
        ; Increasing the divisor makes acceleration milder.
        ; Example: 20ms scroll -> 1 + ((100 - 20) // 10) = +8 gain
        acceleration := (100 - timeSince) // invertedacceleration
        ;acceleration := (75 - timeSince) // invertedacceleration
        gainsteps := gainStepsMin + acceleration
        gainsteps := Min(gainsteps, gainStepsMax) ; Cap at maximum
    } else {
        gainsteps := gainStepsMin
        ;acceleration := -100

        ; Unmute if volume up
        if (up && voicemeeter.strip[stripnum].mute) {
            voicemeeter.strip[stripnum].mute := false
        }

    }

    ; Apply the increment
    step := up ? gainsteps : -gainsteps
    voicemeeter.strip[stripnum].Increment("gain", step)

;    ; Feedback ToolTip
;    ToolTip("acceleration: " acceleration " | Step: " gainsteps)
;    if gainsteps = 0 
;        SetTimer(() => ToolTip(), -5000) 
;    else 
;        SetTimer(() => ToolTip(), -1000) 
}
;@endregion

;@region Bluetooth
; Watch Bluetooth connection - auto restart Voicemeeter

BT_Toggle()
BT_Toggle() {
        if Settings.BTDetect {
            Sleep(1000)
            voicemeeter.On(VMRConsts.Events.DevicesUpdated, BT_Trigger)
        } else {
            voicemeeter.Off(VMRConsts.Events.DevicesUpdated, BT_Trigger)
        }
}

BT_Trigger(*) {
    static counter          := 0
    static startTime        := 0
    static lastTriggerTime  := 0

    BT_Repeats                  := 0
    BT_MaxSeconds               := 2
    BT_MaxMilliseconds          := BT_MaxSeconds * 1000
    BT_Cooldown                 := 5000


    currentTime := A_TickCount
    
    ; 1. COOLDOWN CHECK
    ; If we are still within the 'timer' duration since the last trigger, exit immediately
    if (lastTriggerTime != 0 && (currentTime - lastTriggerTime < BT_Cooldown)) {
        return 
    }
    
    ; 2. RESET LOGIC
    ; If this is the first hit or the detection window expired, reset the start point
    if (counter == 0 || (currentTime - startTime > BT_Cooldown)) {
        startTime := currentTime
        counter := 1
    } else {
        counter += 1
    }

    ; 3. TRIGGER CHECK
    if (counter > BT_Repeats && (currentTime - startTime <= BT_MaxMilliseconds)) {
        lastTriggerTime := currentTime ; Start the cooldown clock
        counter := 0                   ; Reset counter for the next fresh cycle
        BT_HandleRapidChange()
    }
}

BT_HandleRapidChange() {
    voicemeeter.Command.Restart()
}
;@endregion

