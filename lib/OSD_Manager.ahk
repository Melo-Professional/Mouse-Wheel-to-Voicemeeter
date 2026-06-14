/************************************************************************
 * @description OSD Manager
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/30
 * @version 1.4.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

; --- Global State Variables for the Non-Blocking Animation ---
;global OSDSettings
;global OSD_State := "Hidden"                    ; Options: "Hidden", "SlidingUp", "Visible", "SlidingDown"
;global currentY   := 0                          ; Tracks live pixel height of the OSD
;global OSDSettings.Speed := OSDSettings.Speed          ; Pixels moved per tick (Increase for faster animations)
global ANIM_TICK  := 5                          ; Delay between animation steps in milliseconds

CurrentActualThemeOfOSD := "Light"
OSDSettings.DWMCompatible := (VerCompare(A_OSVersion, OSDSettings.DWMMinVer) >= 0)

OSDUpdateColors()
CreateOSD()
UpdateOSDTheme()

UpdateOSDTheme(ThemeMode := Settings.DesiredTheme) {
   global CurrentActualThemeOfOSD

    Settings.DesiredTheme := ThemeMode
    
    ; Sets current theme
    if (ThemeMode == "Auto") {
        OnMessage(0x1A, WindowsThemeChangedToOSD)
        CurrentActualThemeOfOSD := GetWindowsTheme()
    } else {
        OnMessage(0x1A, WindowsThemeChangedToOSD, 0)
        CurrentActualThemeOfOSD := ThemeMode
    }
}

WindowsThemeChangedToOSD(wParam, lParam, msg, hwnd) {
   global CurrentActualThemeOfOSD

    if (Settings.DesiredTheme == "Auto") {
        newTheme := GetWindowsTheme()
        if (newTheme != CurrentActualThemeOfOSD) {
            CurrentActualThemeOfOSD := newTheme
            OSDThemeChange()
        }
    }
}

;OSDThemeChange()
;@region OSD
;@region OSD Create

OSDUpdateColors(theme?){
    global OsdTextDefault, OsdBgColor, OsdBorderColor, OsdProgressFgColor, OsdProgressOver, OsdProgressBgColor, OSDSettings

    THEME := IsSet(theme) ? theme : CurrentActualTheme

    OsdTextDefault:=        OSDSettings.TextDefault%THEME%
    OsdBgColor:=            OSDSettings.BgColor%THEME%
    OsdBorderColor:=        OSDSettings.BorderColor%THEME%
    OsdProgressFgColor:=    OSDSettings.ProgressFgColor%THEME%
    OsdProgressBgColor:=    OSDSettings.ProgressBgColor%THEME%
    OsdProgressOver:=       OSDSettings.ProgressOver100%THEME%
}

CreateOSD() {
    global osdGui, osdDevice, osdProgress, osdVol, posX, startY, finalY, currentY, OSD_State, OSDSettings

    ; GUI Create
    ;osdGui := Gui("-Caption +LastFound +AlwaysOnTop +ToolWindow +E0x20 -DPIScale")
    osdGui := Gui("-Caption +LastFound +AlwaysOnTop +ToolWindow +E0x20 -DPIScale +Owner")
    osdGui.BackColor := OsdBgColor
;    OSDSettings.Width := Round(OSDSettings.FontSize * 22 )
    ProgressHeight := Round((OSDSettings.FontSize / 9) * 6 )
    ProgressGap := Round((OSDSettings.FontSize / 10) * 6 )
    ProgressWidth := OSDSettings.Width - (OSDSettings.MarginX * 2)
    osdGui.MarginX := OSDSettings.MarginX
    osdGui.MarginY := OSDSettings.MarginY
    
    osdGui.SetFont("s" OSDSettings.FontSize " c" OsdTextDefault " w" OSDSettings.FontWeight " q5", OSDSettings.FontName)
    
    ; Strip Name
    osdDevice := osdGui.Add("Text", "Left xm ym w" OSDSettings.Width * 0.7, "OSD")
    osdGui.SetFont("s" OSDSettings.FontSize + 3)

    ; Gain
    osdVol := osdGui.Add("Text", "Right x" osdGui.MarginX + ProgressWidth - (OSDSettings.Width * 0.3) " ym-5 w" OSDSettings.Width * 0.3, "100")
    osdGui.SetFont("s" OSDSettings.FontSize)

    ; Progress Bar
    progressbg := (OsdProgressBgColor = "transparent") ? OsdBgColor : OsdProgressBgColor
    osdProgress := osdGui.Add("Progress", "xm y+" ProgressGap " w" ProgressWidth " h" ProgressHeight " Smooth c" OsdProgressFgColor " Background" progressbg " Range0-" OSDSettings.ProgressMaxValue, 100)

    TransColor := "ABCDEF"
    WinSetTransColor(TransColor, osdGui)

    osdGui.Show("Hide w" OSDSettings.Width)

    if OSDSettings.DWMCompatible {
        Windows11ShadowsandCorners()
    } else {
        global classStyle := DllCall("User32.dll\GetClassLongPtr", "Ptr", osdGui.Hwnd, "Int", -26, "Ptr")
        Win10Corners()
    }

    ; Start Position Math
    osdGui.GetClientPos(,, &guiW, &guiH)
    posX := (A_ScreenWidth - guiW) // 2
    finalY := (OSDSettings.Position = "bottom") ? A_ScreenHeight - guiH - OSDSettings.EdgeDistance : OSDSettings.EdgeDistance
    isBottom := (finalY > A_ScreenHeight / 2)
    startY := isBottom ? (finalY + OSDSettings.SlideDistance) : (finalY - OSDSettings.SlideDistance)

    currentY := startY
    OSD_State := "Hidden"
    osdGui.Move(posX, startY)
}

/* 
ResizeOSD(OSDSize?, FontSize? ){
    global osdGui, osdDevice, osdProgress, osdVol, posX, startY, finalY

    ProgressHeight := Round((OSDSettings.FontSize / 9) * 6 )
    ProgressGap := Round((OSDSettings.FontSize / 10) * 6 )
    ProgressWidth := OSDSettings.Width - (OSDSettings.MarginX * 2)
    osdGui.MarginX := OSDSettings.MarginX
    osdGui.MarginY := OSDSettings.MarginY

    osdDevice.SetFont("s" OSDSettings.FontSize + 3)
    osdVol.SetFont("s" OSDSettings.FontSize)
    osdProgress.Opt("y+" ProgressGap " w" ProgressWidth " h" ProgressHeight)
;    ToolTip(OSDSettings.Width)
    osdGui.Show("NoActivate w" OSDSettings.Width)
}
 */

Windows11ShadowsandCorners(){
    ; 1. Force the Non-Client area rendering policy to "Enabled"
    ncPolicy := Buffer(4, 0)
    NumPut("Int", 2, ncPolicy, 0) ; DWMNCRP_ENABLED = 2
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", osdGui.Hwnd, "UInt", 2, "Ptr", ncPolicy, "UInt", 4)

    ; 2. OPTIONAL CRITICAL FIX FOR INDEPENDENT CORNERS:
    ; If you use RoundedCorners in your settings, keep your SetWindowRgn code.
    ; This line tells DWM to use the small/delicate shadow template profiling:
    cornerPreference := Buffer(4, 0)
    NumPut("Int", 5, cornerPreference, 0) ; DWMWCP_ROUNDSMALL = 3 (Forces a tight, delicate shadow profile)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", osdGui.Hwnd, "UInt", 33, "Ptr", cornerPreference, "UInt", 4)

    ; 3. Inject a minimal hardware layout margin so the soft shadow map initiates
    margins := Buffer(16, 0)
    NumPut("Int", 1, margins, 0)  ; Left
    NumPut("Int", 1, margins, 4)  ; Right
    NumPut("Int", 1, margins, 8)  ; Top
    NumPut("Int", 1, margins, 12) ; Bottom
    DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", osdGui.Hwnd, "Ptr", margins)
}

Win10Corners(){
    osdGui.GetPos(,, &guiWidth, &guiHeight)
    ; --- FALLBACK FOR WINDOWS 10 (corners for now) ---
    if (OSDSettings.HasProp("RoundedCorners") && OSDSettings.RoundedCorners > 0) {
        hRgn := DllCall("Gdi32.dll\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", guiWidth, "Int", guiHeight, "Int", OSDSettings.RoundedCorners, "Int", OSDSettings.RoundedCorners, "Ptr")
        DllCall("User32.dll\SetWindowRgn", "Ptr", osdGui.Hwnd, "Ptr", hRgn, "Int", true)
    }
}
;@endregion

;@region OSD Show
CheckVolumeChange(stripIdx, *) {
    global LastGainValues, osdGui, OSD_State, ANIM_TICK
    
    if (!OSDSettings.UseOSD || !IsObject(osdGui))
        return

    if !(LastGainValues.Has(stripIdx))
        LastGainValues[stripIdx] := voicemeeter.Strip[stripIdx].Gain

    currentGain := voicemeeter.Strip[stripIdx].Gain
    
    if (currentGain != LastGainValues[stripIdx]) {
        LastGainValues[stripIdx] := currentGain
        
        ; If OSD is active or intermediate, refresh data and restart the stay-on-screen timer
        if (OSD_State != "Hidden") {
            UpdateOSDValues(stripIdx)
            SetTimer(HideOSDTrigger, -OSDSettings.TimeOut)
            
            ; If it was descending, catch it mid-air and reverse it back up smoothly
            if (OSD_State == "SlidingDown") {
                OSD_State := "SlidingUp"
                SetTimer(AnimateSlideDown, 0)
                SetTimer(AnimateSlideUp, ANIM_TICK)
            }
        } else {
            ShowOSD(stripIdx)
        }
    }
}

UpdateOSDValues(stripnum) {
    global osdDevice, osdProgress, osdVol
    
    strip := voicemeeter.Strip[stripnum]
    db := strip.gain
    
    normalized := (db + 60) / 60 
    displayPercent := (db > 0) ? Round(100 + (db * 5)) : Round((Max(0, normalized) ** 2) * 100)

    label := strip["Label"]
    osdDevice.Value := (label != "" ? label : strip.Name)
    osdVol.Value := displayPercent

    if (displayPercent > 100) {
        osdProgress.Opt("+c" OsdProgressOver)
    } else {
        osdProgress.Opt("+c" OsdProgressFgColor)
    }

    osdProgress.Value := Min(OSDSettings.ProgressMaxValue, displayPercent)
}

ShowOSD(stripnum) {
    global OSD_State, ANIM_TICK
    ;ShadowsandCorners()
    UpdateOSDValues(stripnum)
    SetTimer(HideOSDTrigger, 0) ; Clear any pending auto-hide callbacks

    if (OSD_State == "Hidden" || OSD_State == "SlidingDown") {
        if !OSDSettings.DWMCompatible {       ; applying windows 10 borders
            DllCall("User32.dll\SetClassLongPtr", "Ptr", osdGui.Hwnd, "Int", -26, "Ptr", classStyle | 0x00020000)
        }
        OSD_State := "SlidingUp"
        SetTimer(AnimateSlideDown, 0)
        SetTimer(AnimateSlideUp, ANIM_TICK)
    }
}

AnimateSlideUp() {
    global currentY, OSD_State, finalY, startY, posX, osdGui, ANIM_TICK, OSDSettings

    isBottomConfig := (finalY > startY)
    
    reachedTarget := false
    if (isBottomConfig) {
        currentY += OSDSettings.Speed
        if (currentY >= finalY) {
            currentY := finalY
            reachedTarget := true
        }
    } else {
        currentY -= OSDSettings.Speed
        if (currentY <= finalY) {
            currentY := finalY
            reachedTarget := true
        }
    }

    ; flags: SWP_NOSIZE (0x0001) | SWP_NOMOVE (0x0002) | SWP_NOACTIVATE (0x0010) 
    ; flags: SWP_NOOWNERZORDER (0x0060) | SWP_SHOWWINDOW (0x0040) | SWP_FRAMECHANGED (0x0020)
    ; SWP_NOSIZE (0x0001) | SWP_SHOWWINDOW (0x0040) | SWP_NOACTIVATE (0x0010) = 0x0051
    DllCall("SetWindowPos", "Ptr", osdGui.Hwnd, "Ptr", -1, "Int", posX, "Int", currentY, "Int", 0, "Int", 0, "UInt", 0x0051)
;    DllCall("SetWindowPos", "Ptr", osdGui.Hwnd, "Ptr", -1, "Int", posX, "Int", currentY, "Int", 0, "Int", 0, "UInt", 0x0075) ; sombra + movimento correto


    if (reachedTarget) {
        SetTimer(AnimateSlideUp, 0)
        OSD_State := "Visible"
        SetTimer(HideOSDTrigger, -OSDSettings.TimeOut)
    }
}

AnimateSlideDown() {
    global currentY, OSD_State, finalY, startY, posX, osdGui, OSDSettings

    isBottomConfig := (finalY > startY)
    
    reachedTarget := false
    if (isBottomConfig) {
        currentY -= OSDSettings.Speed
        if (currentY <= startY) {
            currentY := startY
            reachedTarget := true
        }
    } else {
        currentY += OSDSettings.Speed
        if (currentY >= startY) {
            currentY := startY
            reachedTarget := true
        }
    }
    
    ; Using 0x0051 here as well ensures it doesn't try to grab focus while leaving the screen
    DllCall("SetWindowPos", "Ptr", osdGui.Hwnd, "Ptr", -1, "Int", posX, "Int", currentY, "Int", 0, "Int", 0, "UInt", 0x0051)
    
    if (reachedTarget) {
        SetTimer(AnimateSlideDown, 0)
        osdGui.Hide()
        OSD_State := "Hidden"
    }
}

HideOSD(*) {
    ; Acts as a clean wrapper for external file hooks/OnMessage bindings
    HideOSDTrigger()
}

HideOSDTrigger() {
    global OSD_State, ANIM_TICK
    if (OSD_State == "Visible" || OSD_State == "SlidingUp") {
        OSD_State := "SlidingDown"
        SetTimer(AnimateSlideUp, 0)
        SetTimer(AnimateSlideDown, ANIM_TICK)
            if !OSDSettings.DWMCompatible {        ; cleaning windows 10 borders
                DllCall("User32.dll\SetClassLongPtr", "Ptr", osdGui.Hwnd, "Int", -26, "Ptr", classStyle)
        }
    }
}

OSDThemeChange(){
    WinWaitClose(osdGui.Hwnd)
    OSDUpdateColors()
    osdGui.Destroy()
    CreateOSD()
}

WinVisible(hwnd) {
    return (DllCall("IsWindowVisible", "Ptr", hwnd) != 0)
}

;@endregion
;@endregion