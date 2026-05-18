#Requires AutoHotkey v2.0

; --- Global State Variables for the Non-Blocking Animation ---
global OSDSettings
global OSD_State := "Hidden"                    ; Options: "Hidden", "SlidingUp", "Visible", "SlidingDown"
global currentY   := 0                          ; Tracks live pixel height of the OSD
global SLIDE_STEP := OSDSettings.Speed          ; Pixels moved per tick (Increase for faster animations)
global ANIM_TICK  := 5                          ; Delay between animation steps in milliseconds


;@region OSD
;@region OSD Create

OSDUpdateColors(theme?){
    global OsdTextDefault, OsdBgColor, OsdBorderColor, OsdProgressFgColor, OsdProgressOver, OsdProgressBgColor

    THEME := IsSet(theme) ? theme : CurrentActualTheme

    OsdTextDefault:=        OSDSettings.TextDefault%THEME%
    OsdBgColor:=            OSDSettings.BgColor%THEME%
    OsdBorderColor:=        OSDSettings.BorderColor%THEME%
    OsdProgressFgColor:=    OSDSettings.ProgressFgColor%THEME%
    OsdProgressBgColor:=    OSDSettings.ProgressBgColor%THEME%
    OsdProgressOver:=       OSDSettings.ProgressOver100%THEME%
}

CreateOSD() {
    global osdGui, osdDevice, osdProgress, osdVol, posX, startY, finalY, currentY, OSD_State

    ; GUI Create
    osdGui := Gui("-Caption +LastFound +AlwaysOnTop +ToolWindow +E0x20 -DPIScale")
    osdGui.BackColor := OsdBgColor
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
    osdProgress := osdGui.Add("Progress", "xm y+" ProgressGap " w" ProgressWidth " h" ProgressHeight " c" OsdProgressFgColor " Background" progressbg " Range0-" OSDSettings.ProgressMaxValue, 100)

    TransColor := "ABCDEF"
    WinSetTransColor(TransColor, osdGui)

    osdGui.Show("Hide w" OSDSettings.Width)

    ; Border
    if OSDSettings.ColoredBorder{
        ColoredBorder(osdGui, OSDSettings.RoundedCorners, OsdBorderColor, 2)
    } else {
        NonColoredBorder()
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
    ToolTip(OSDSettings.Width)
    osdGui.Show("NoActivate w" OSDSettings.Width)
}

NonColoredBorder() {
    global osdGui
    if (!IsObject(osdGui))
        return
    osdGui.GetClientPos(,, &w, &h)
    if (w > 0 && h > 0) {
        WinSetRegion("0-0 w" w " h" h " r" OSDSettings.RoundedCorners "-" OSDSettings.RoundedCorners, osdGui.Hwnd)
    }
}

ColoredBorder(guiObj, edge, color, thickness := 2) {
    guiObj.GetPos(,, &w, &h)
    if (!w || !h)
        return

    hRgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w, "Int", h, "Int", edge, "Int", edge, "Ptr")
    DllCall("user32\SetWindowRgn", "Ptr", guiObj.Hwnd, "Ptr", hRgn, "Int", 1)
    
    guiObj.Add("Text", "x0 y0 w" w " h" thickness " +ReadOnly Background" color) ; Top
    guiObj.Add("Text", "x0 y" h-thickness " w" w " h" thickness " +ReadOnly Background" color) ; Bottom
    guiObj.Add("Text", "x0 y0 w" thickness " h" h " +ReadOnly Background" color) ; Left
    guiObj.Add("Text", "x" w-thickness " y0 w" thickness " h" h " +ReadOnly Background" color) ; Right
}
;@endregion

;@region OSD Show
CheckVolumeChange(stripIdx, *) {
    global LastGainValues, osdGui, OSD_State, ANIM_TICK
    
    if (!OSDSettings.UseOSD || !IsObject(osdGui))
        return

    if !LastGainValues.Has(stripIdx)
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
    
    UpdateOSDValues(stripnum)
    SetTimer(HideOSDTrigger, 0) ; Clear any pending auto-hide callbacks

    if (OSD_State == "Hidden" || OSD_State == "SlidingDown") {
        OSD_State := "SlidingUp"
        SetTimer(AnimateSlideDown, 0)
        SetTimer(AnimateSlideUp, ANIM_TICK)
    }
}

AnimateSlideUp() {
    global currentY, OSD_State, finalY, startY, SLIDE_STEP, posX, osdGui, ANIM_TICK, OSDSettings
    global SLIDE_STEP := OSDSettings.Speed
    isBottomConfig := (finalY > startY)
    
    reachedTarget := false
    if (isBottomConfig) {
        currentY += SLIDE_STEP
        if (currentY >= finalY) {
            currentY := finalY
            reachedTarget := true
        }
    } else {
        currentY -= SLIDE_STEP
        if (currentY <= finalY) {
            currentY := finalY
            reachedTarget := true
        }
    }
    
    ; SWP_NOSIZE (0x0001) | SWP_SHOWWINDOW (0x0040) | SWP_NOACTIVATE (0x0010) = 0x0051
    DllCall("SetWindowPos", "Ptr", osdGui.Hwnd, "Ptr", -1, "Int", posX, "Int", currentY, "Int", 0, "Int", 0, "UInt", 0x0051)
    
    if (reachedTarget) {
        SetTimer(AnimateSlideUp, 0)
        OSD_State := "Visible"
        SetTimer(HideOSDTrigger, -OSDSettings.TimeOut)
    }
}

AnimateSlideDown() {
    global currentY, OSD_State, finalY, startY, SLIDE_STEP, posX, osdGui, OSDSettings
    global SLIDE_STEP := OSDSettings.Speed
    isBottomConfig := (finalY > startY)
    
    reachedTarget := false
    if (isBottomConfig) {
        currentY -= SLIDE_STEP
        if (currentY <= startY) {
            currentY := startY
            reachedTarget := true
        }
    } else {
        currentY += SLIDE_STEP
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