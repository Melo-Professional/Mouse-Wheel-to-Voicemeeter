;@region Description
/************************************************************************
 * @description Control Voicemeeter virtual Inputs volumes using the mouse wheel over the taskbar.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/13
 * @releasedate 2022/05/11
 * @version 3.69.2.0
 * @github https://github.com/Melo-Professional/Mouse-Wheel-to-Voicemeeter
 * @credits VMR AHK https://github.com/SaifAqqad/VMR.ahk
 * @credits trismarck code from here: https://www.autohotkey.com/board/topic/96139-detect-screen-edges-two-monitors/
 ***********************************************************************/

/*
TO DO
Monitor options
osd_manager:
    TransColor := "ABCDEF" ???
    WinSetTransColor(TransColor, osdGui) ???

    I need to update the menu and menu template to check
    if it is currently suspended or paused and check the boxes accodanly.
    There was a problem when gui options was opened and the user change the theme from menu and cancel in the
    gui options the theme was applied back. I fixed it by loadINI whenever the user cancel the gui options.
    But anyway I need to update the menu template.
*/

AppName := "Mouse Wheel to Voicemeeter"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "3.69.2.0"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "Control Voicemeeter virtual Inputs volumes using the mouse wheel over the taskbar."
;@endregion

;_bkpMode := "AppVersionAndMinutes"

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
A_MenuMaskKey := "vkFF"
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
ListLines(False)
KeyHistory(0)
CoordMode("Mouse", "Screen")
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Backup>
#Include *i <_Config&Vars>
#Include *i <_HelperFuncs>
#Include *i <_SaveSettings>
;#Include *i <_MessageManager>
;#Include *i <_TrayIconHandler>
#Include *i <_Theme>
;#Include *i <_FrostedTheme>
#Include *i <_TitleBar>
#Include *i <_GuiTracker>
;#Include *i <_ModernSlider>
#Include *i <_Color_Picker_Dialog>
;#Include *i <_HotkeysRecorder>
;#Include *i <_ODColors>
;#Include *i <_OSDCustom>
#Include *i <_AutoUpdater>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <App_Funcs>
#Include <App_Options>
#Include <OSD_Options>
#Include <VMR>
#Include <OSD_Manager>
;@endregion

;@region Startup
IsFunctionDefined("StartMenu")			? %"StartMenu"%()			: ""
IsFunctionDefined("Menu_Custom")		? %"Menu_Custom"%()			: ""
IsFunctionDefined("StartAutoUpdater")	? %"StartAutoUpdater"%()	: ""
;@endregion
;@endregion

;@region Login VM
LoginVMR()
;@endregion

;@region Monitor, Faders and Current Gains
Faders := GetFaders()
ListenAndLastGainValues()

if !A_Args.Length && IsSet(SplashScreen) {
    SplashScreen()
}
;@endregion


Global ready := true
SoundPlayWin("Windows Print Complete")
;@region HotKeys

$~WheelUp:: {
    if MouseIsOverTaskbar(&targetWin, &mx, &my) && ready
        AdjustVolume(true, targetWin, mx, my)
}

$~WheelDown:: {
    if MouseIsOverTaskbar(&targetWin, &mx, &my) && ready
        AdjustVolume(false, targetWin, mx, my)
}

$^sc046:: Reload()          ; Ctrl + ScrollLock
$+^sc046:: RestartAll()     ; Ctrl + Shift + ScrollLock

;@endregion
;@region Mouse Wheel Logic
/* AdjustVolume(up, targetWin, x, y) {
    global voicemeeter, Faders
    static lastX := -1, lastY := -1
    static cachedStrip := 1

    mousetolerance := 18

    if (Abs(x - lastX) > mousetolerance || Abs(y - lastY) > mousetolerance) {
        
        try {
            WinGetPos(&tX, &tY, &tW, &tH, "ahk_id " targetWin)
        } 
        catch {
            tX := 0, tY := 0, tW := A_ScreenWidth, tH := A_ScreenHeight
        }

        ; Calculate portion based on taskbar orientation
        if (tW >= tH) {
            ; Horizontal taskbar (top or bottom)
            portion := Floor((x - tX) / Max(1, tW) * Faders.Length) + 1
        } else {
            ; Vertical taskbar (left or right)
            portion := Floor((y - tY) / Max(1, tH) * Faders.Length) + 1
        }

        ; Safe clamp: Ensures 'portion' stays strictly between 1 and Faders.Length
        ; This prevents potential Array Index Errors if x/y tracking slips outside the taskbar frame
        portion := Max(1, Min(portion, Faders.Length))

        cachedStrip := Faders[portion]
        lastX := x
        lastY := y
    }

    stripnum := cachedStrip

    ; ==================== Acceleration Logic ====================
    tsPrior := IsNumber(A_TimeSincePriorHotkey) ? A_TimeSincePriorHotkey : 300
    timeSince := (tsPrior == -1) ? 300 : tsPrior

    if (timeSince < 100) {
        invertedacceleration := Round(100 / General.WheelSpeed)
        acceleration := (100 - timeSince) // invertedacceleration
        gainsteps := General.gainStepsMin + acceleration
        gainsteps := Min(gainsteps, General.gainStepsMax)
    } else {
        gainsteps := General.gainStepsMin
        if (up && voicemeeter.strip[stripnum].mute)
            voicemeeter.strip[stripnum].mute := false
    }

    step := up ? gainsteps : -gainsteps
    voicemeeter.strip[stripnum].Increment("gain", step)
}
 */

AdjustVolume(up, targetWin, x, y) {
    global voicemeeter, Faders

    static cache := Map()
    static lastStrip := 1

    if !cache.Has(targetWin) {
        WinGetPos(&x1, &y1, &w, &h, "ahk_id " targetWin)
        cache[targetWin] := {x:x1, y:y1, w:w, h:h}
    }

    tb := cache[targetWin]

    portion :=
        (tb.w >= tb.h)
        ? Floor((x - tb.x) / tb.w * Faders.Length) + 1
        : Floor((y - tb.y) / tb.h * Faders.Length) + 1

    portion := Max(1, Min(portion, Faders.Length))

    stripnum := Faders[portion]


    ; ==================== Acceleration Logic ====================
    tsPrior := IsNumber(A_TimeSincePriorHotkey) ? A_TimeSincePriorHotkey : 300
    timeSince := (tsPrior == -1) ? 300 : tsPrior

    if (timeSince < 100) {
        invertedacceleration := Round(100 / General.WheelSpeed)
        acceleration := (100 - timeSince) // invertedacceleration
        gainsteps := General.gainStepsMin + acceleration
        gainsteps := Min(gainsteps, General.gainStepsMax)
    } else {
        gainsteps := General.gainStepsMin
        if (up && voicemeeter.strip[stripnum].mute){
            voicemeeter.strip[stripnum].mute := false
            try {
                if (Round(voicemeeter.macrobutton.GetStatus(MacroButtonMuteUnmuteVirtualInput[portion] + 1, 0)) = 1)
                    voicemeeter.macrobutton.SetStatus(MacroButtonMuteUnmuteVirtualInput[portion] + 1, 0.0)
            }
        }
    }

    step := up ? gainsteps : -gainsteps
    voicemeeter.strip[stripnum].Increment("gain", step)
}

;@endregion

;@region Bluetooth
; Watch Bluetooth connection - auto restart Voicemeeter

BT_Toggle()
BT_Toggle() {
        voicemeeter.Off(VMRConsts.Events.DevicesUpdated)
        if (General.BTDetect && !A_IsSuspended) {
            Sleep(1000)
            voicemeeter.On(VMRConsts.Events.DevicesUpdated, BT_Trigger)
        } else {
            ;voicemeeter.Off(VMRConsts.Events.DevicesUpdated, BT_Trigger)
        }
}

BT_Trigger(*) {
    if !ready
        return
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