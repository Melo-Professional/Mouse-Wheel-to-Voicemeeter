/************************************************************************
 * @description OSDCustom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.6.0
 ***********************************************************************/

#Requires AutoHotkey v2.0
 
Global OSDSettings := {
    DWMMinVer:                  "10.0.22000",
    DWMCompatible:              false,
    UseOSD:                     true,
    Monitor:                    "auto",             ; Options: "auto" (active window monitor), 1, 2, 3, etc. Falls back to Primary if invalid.
    MinWidth:                   20,
    MaxWidth:                   600,
    FontSize:                   11,
    TimeOut:                    1800,
    Speed:                      4,                  ; Pixels moved per tick
    Position:                   "x0.50 y0.50",
    SlideDistance:              30,
    FontName:                   "Cascadia Mono",    ; monospace fonts = Cascadia Mono, Consolas, Courier, Courier New, Fixedsys, Lucida Console, and Terminal
    FontWeight:                 1000,               ; Standard Windows weights: 400=Normal, 700=Bold, 1000=Ultra-Bold
    MarginX:                    24,
    MarginY:                    16,
    Opacity:                    245,
    RoundedCorners:             15,
    ProgressMaxValue:           100,

    ; Theme
    Theme:                      "Auto",                           ; "Light" / "Dark" / "Auto" / Settings.DesiredTheme
    Theme:                      Settings.DesiredTheme,            ; "Light" / "Dark" / "Auto"

    ; lightmode
    TextDefaultLight:           "5a5555",
    BgColorLight:               "F5F9FB",
    BorderColorLight:           "ffffff",
    ProgressFgColorLight:       "0067C0",
    ProgressBgColorLight:       "EDF1F2",           ; HEX or "transparent"
    ProgressOver100Light:       "FF5555",

    ; darkmode
    TextDefaultDark:            "d8d8d8",
    BgColorDark:                "272525",
    BorderColorDark:            "272525",
    ProgressFgColorDark:        "4CC2FF",
    ProgressBgColorDark:        "333333",           ; HEX or "transparent"
    ProgressOver100Dark:        "FF5555"
}

OSDSettings.DWMCompatible := (VerCompare(A_OSVersion, OSDSettings.DWMMinVer) >= 0)

class OSDCustom {
    __New(title := "Custom OSD", options := "-Caption +AlwaysOnTop +ToolWindow +E0x20 -DPIScale") {
        this.Title := title
        ; Add +Owner to prevent taskbar presence and help isolate window styles
        this.Options := options " +Owner" 
        this.MyGui := ""
        this.TextCtrl := "" 
        
        ; Animation & Opacity Properties
        this.State := "Hidden" 
        this.PosX := 0
        this.CurrentY := 0
        this.StartY := 0
        this.FinalY := 0
        this.CurrentAlpha := 0
        this.AlphaStep := 0
        
        this.SlideInCb := ObjBindMethod(this, "AnimateSlideIn")
        this.SlideOutCb := ObjBindMethod(this, "AnimateSlideOut")
        this.DestroyCb := ObjBindMethod(this, "Destroy")

        ; --- LIVE THEME MONITOR ENGINE ---
        ; Listens for system-wide environmental metric updates (such as theme toggles)
        OnMessage(0x001A, ObjBindMethod(this, "OnSettingChange")) ; 0x001A = WM_SETTINGCHANGE
    }

    /**
     * Resolves the required property value dynamically based on the current context theme state.
     */
    GetCurrentThemeColor(propName) {
        currentMode := OSDSettings.Theme
        if (StrLower(currentMode) == "auto") {
            try {
                ; Query Windows Personalization subkey directly for immediate state validation
                isLight := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
                currentMode := isLight ? "Light" : "Dark"
            } catch {
                currentMode := "Light" ; Safe fallback assignment
            }
        }
        return OSDSettings.%propName currentMode%
    }

    /**
     * Updates control background and foreground values securely on operational interfaces.
     */
    ApplyThemeColors() {
        if (!this.MyGui)
            return

        resolvedBg := this.GetCurrentThemeColor("BgColor")
        resolvedText := this.GetCurrentThemeColor("TextDefault")

        this.MyGui.BackColor := resolvedBg
        this.TextCtrl.SetFont("c" resolvedText)
        
        ; Force asynchronous UI control updates
        this.TextCtrl.Opt("+Background" resolvedBg)
        this.TextCtrl.Redraw()
    }

    /**
     * Pipeline callback intercepts Windows broadcast parameters to handle dynamic adjustments.
     */
    OnSettingChange(wParam, lParam, msg, hwnd) {
        if (OSDSettings.Theme == "Auto") {
            ; Apply visual properties immediately across the thread layout
            this.ApplyThemeColors()
        }
    }

    /**
     * Displays the custom animated OSD on the designated target monitor.
     */
    Show(text := A_LineFile, Position := "", TimeOut := "") {
        if (Position == "")
            Position := this.HasProp("Position") ? this.Position : OSDSettings.Position
        if (TimeOut == "")
            TimeOut := this.HasProp("TimeOut") ? this.TimeOut : OSDSettings.TimeOut
        
        this.FontName   := this.HasProp("FontName")     ? this.FontName     : OSDSettings.FontName
        this.FontSize   := this.HasProp("FontSize")     ? this.FontSize     : OSDSettings.FontSize
        this.FontWeight := this.HasProp("FontWeight")   ? this.FontWeight   : OSDSettings.FontWeight
        this.MinWidth   := this.HasProp("MinWidth")     ? this.MinWidth     : OSDSettings.MinWidth
        this.MaxWidth   := this.HasProp("MaxWidth")     ? this.MaxWidth     : OSDSettings.MaxWidth
        this.MarginX    := this.HasProp("MarginX")      ? this.MarginX      : OSDSettings.MarginX
        this.MarginY    := this.HasProp("MarginY")      ? this.MarginY      : OSDSettings.MarginY

        ;textBounds := this.CalculateTextSize(text, OSDSettings.FontName, OSDSettings.FontSize, OSDSettings.FontWeight, OSDSettings.MaxWidth - (OSDSettings.MarginX * 2))
        textBounds := this.CalculateTextSize(text, this.FontName, this.FontSize, this.FontWeight, this.MaxWidth - (this.MarginX * 2))
        
        idealGuiWidth := textBounds.W + (this.MarginX * 2)
        finalGuiWidth := Max(this.MinWidth, Min(idealGuiWidth, this.MaxWidth))
        finalTextWidth := finalGuiWidth - (this.MarginX * 2)

        if (!this.MyGui) {
            this.MyGui := Gui(this.Options, this.Title)
            this.MyGui.OnEvent("Close", (*) => this.Destroy())
            
            this.MyGui.MarginX := this.MarginX
            this.MyGui.MarginY := this.MarginY
            
            this.MyGui.SetFont("s" this.FontSize " w" this.FontWeight, this.FontName)
            this.TextCtrl := this.MyGui.AddText("w" finalTextWidth " h" textBounds.H " Center", text)
            
            ; Map properties based on the theme
            this.ApplyThemeColors()
        } else {
            SetTimer(this.DestroyCb, 0) 
            this.TextCtrl.Move(,, finalTextWidth, textBounds.H)
            this.TextCtrl.Value := text
            
            ; Ensure runtime text adaptations reflect contextual adjustments
            this.ApplyThemeColors()
        }

        ; 3. Render hidden to compute actual layout shapes
        this.MyGui.Show("w" finalGuiWidth " h" (textBounds.H + (this.MarginY * 2)) " Hide")
        this.MyGui.GetPos(,, &guiWidth, &guiHeight)

    ; SHADOWS AND ROUNDED CORNERS
    if OSDSettings.DWMCompatible {      ; Win 11 DWM
        ; SHADOWS AND ROUNDED CORNERS
        ; 1. Force the Non-Client area rendering policy to "Enabled"
        ncPolicy := Buffer(4, 0)
        NumPut("Int", 2, ncPolicy, 0) ; DWMNCRP_ENABLED = 2
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.MyGui.Hwnd, "UInt", 2, "Ptr", ncPolicy, "UInt", 4)

        ; 2. OPTIONAL CRITICAL FIX FOR INDEPENDENT CORNERS:
        cornerPreference := Buffer(4, 0)
        NumPut("Int", 2, cornerPreference, 0) ; DWMWCP_ROUNDSMALL = 3
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.MyGui.Hwnd, "UInt", 33, "Ptr", cornerPreference, "UInt", 4)

        ; 3. Inject a minimal hardware layout margin so the soft shadow map initiates
        margins := Buffer(16, 0)
        NumPut("Int", 1, margins, 0)  ; Left
        NumPut("Int", 1, margins, 4)  ; Right
        NumPut("Int", 1, margins, 8)  ; Top
        NumPut("Int", 1, margins, 12) ; Bottom
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", this.MyGui.Hwnd, "Ptr", margins)
            
    } else {        ; WIN 10
		; Create the smooth rounded region mask (safe to do before showing)
		if (OSDSettings.HasProp("RoundedCorners") && OSDSettings.RoundedCorners > 0) {
			hRgn := DllCall("Gdi32.dll\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", guiWidth, "Int", guiHeight, "Int", OSDSettings.RoundedCorners, "Int", OSDSettings.RoundedCorners, "Ptr")
			DllCall("User32.dll\SetWindowRgn", "Ptr", this.MyGui.Hwnd, "Ptr", hRgn, "Int", true)
		}

		; FETCH current class long values
		classStyle := DllCall("User32.dll\GetClassLongPtr", "Ptr", this.MyGui.Hwnd, "Int", -26, "Ptr")

		; INJECT the class drop shadow flag (CS_DROPSHADOW = 0x00020000)
		DllCall("User32.dll\SetClassLongPtr", "Ptr", this.MyGui.Hwnd, "Int", -26, "Ptr", classStyle | 0x00020000)

        ; SHOW / REFRESH YOUR OSD HERE
        ; Combined flags: SWP_NOSIZE (0x0001) | SWP_NOMOVE (0x0002) | SWP_NOACTIVATE (0x0010) | SWP_NOOWNERZORDER (0x0060) = 0x0077
        ; Also changed hWndInsertAfter from 0 (HWND_TOP) to -1 (HWND_TOPMOST) to keep the OSD on top without activating it.
        DllCall("User32.dll\SetWindowPos", "Ptr", this.MyGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0077)

		; RESTORE the class to normal immediately. 
		;    Your OSD keeps its shadow, but subsequent windows (like 'About') won't inherit it!
		DllCall("User32.dll\SetClassLongPtr", "Ptr", this.MyGui.Hwnd, "Int", -26, "Ptr", classStyle)

    }

        ; Initialize coordinate variables explicitly so compilation scopes match
        monLeft := 0, monTop := 0, monRight := 0, monBottom := 0
        targetMonIndex := 1 
        
        ; 4. SMART MONITOR DETECTION & RESOLUTION RETRIEVAL
        if (!OSDSettings.HasProp("Monitor") || StrLower(OSDSettings.Monitor) == "auto") {
            activeWin := WinExist("A")
            if (activeWin) {
                try targetMonIndex := this.GetMonitorFromWindow(activeWin)
            }
        } else if IsInteger(OSDSettings.Monitor) {
            if (OSDSettings.Monitor <= MonitorGetCount() && OSDSettings.Monitor > 0) {
                targetMonIndex := OSDSettings.Monitor
            }
        }

        ; Fetch the working boundaries (excludes taskbars) via native v2 commands
        try {
            MonitorGetWorkArea(targetMonIndex, &monLeft, &monTop, &monRight, &monBottom)
        } catch {
            MonitorGetWorkArea(1, &monLeft, &monTop, &monRight, &monBottom)
        }

        monWidth := monRight - monLeft
        monHeight := monBottom - monTop

        ; 5. Parse screen positions relative to the target monitor's bounding box
        targetX := monLeft + (monWidth * 0.5)
        targetY := monTop + (monHeight * 0.5)
        
        if RegExMatch(Position, "i)x([\d\.]+)", &matchX)
            targetX := monLeft + (monWidth * Float(matchX[1]))
        if RegExMatch(Position, "i)y([\d\.]+)", &matchY)
            targetY := monTop + (monHeight * Float(matchY[1]))

        this.PosX := Max(monLeft, Min(targetX - Integer(guiWidth / 2), monRight - guiWidth))
        this.FinalY := Max(monTop, Min(targetY - Integer(guiHeight / 2), monBottom - guiHeight))

        ; 6. Determine animation vectors relative to monitor height split lines
        this.IsBottomHalf := (this.FinalY >= (monTop + (monHeight / 2) - guiHeight / 2))
        this.StartY := this.IsBottomHalf ? (this.FinalY + OSDSettings.SlideDistance) : (this.FinalY - OSDSettings.SlideDistance)

        totalTicks := OSDSettings.SlideDistance / OSDSettings.Speed
        this.AlphaStep := OSDSettings.Opacity / totalTicks

        ; 7. Execution state routing logic
        if (this.State == "Hidden" || this.State == "SlidingOut") {
            SetTimer(this.SlideOutCb, 0) 
            
            this.CurrentY := this.StartY
            this.CurrentAlpha := 0
            WinSetTransparent(Integer(this.CurrentAlpha), this.MyGui.Hwnd)
            
            DllCall("SetWindowPos", "Ptr", this.MyGui.Hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)
            
            this.State := "SlidingIn"
            this.TargetDuration := TimeOut 
            SetTimer(this.SlideInCb, 5) 
        }
        else if (this.State == "Visible" || this.State == "SlidingIn") {
            this.CurrentY := this.FinalY
            this.CurrentAlpha := OSDSettings.Opacity
            WinSetTransparent(Integer(this.CurrentAlpha), this.MyGui.Hwnd)
            DllCall("SetWindowPos", "Ptr", this.MyGui.Hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)
            
            this.State := "Visible"
            if (TimeOut > 0)
                SetTimer(this.DestroyCb, -TimeOut)
        }
    }

    GetMonitorFromWindow(hwnd) {
        hMonitor := DllCall("User32.dll\MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr") ; MONITOR_DEFAULTTONEAREST
        loop MonitorGetCount() {
            if (this.GetMonitorHandle(A_Index) == hMonitor)
                return A_Index
        }
        return 1
    }

    GetMonitorHandle(monitorIndex) {
        static DISPLAY_DEVICE_SIZE := 424
        dd := Buffer(DISPLAY_DEVICE_SIZE, 0)
        NumPut("UInt", DISPLAY_DEVICE_SIZE, dd, 0)
        
        if DllCall("User32.dll\EnumDisplayDevicesW", "Ptr", 0, "UInt", monitorIndex - 1, "Ptr", dd, "UInt", 0) {
            deviceName := StrGet(dd.Ptr + 4, 32, "UTF-16")
            return DllCall("User32.dll\CreateDCW", "Str", deviceName, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr")
        }
        return 0
    }

    CalculateTextSize(text, fontName, fontSize, fontWeight, maxW) {
        hdc := DllCall("GetDC", "Ptr", 0, "Ptr")
        logPixelsY := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 90) ; 90 = LOGPIXELSY
        
        hFont := DllCall("CreateFont", "Int", -DllCall("MulDiv", "Int", fontSize, "Int", logPixelsY, "Int", 72), "Int", 0, "Int", 0, "Int", 0, "Int", fontWeight, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "Str", fontName, "Ptr")
        
        obm := DllCall("SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr")
        RECT := Buffer(16, 0)
        NumPut("Int", maxW, RECT, 8) 
        
        DllCall("User32.dll\DrawText", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", RECT, "UInt", 0x450)
        
        DllCall("SelectObject", "Ptr", hdc, "Ptr", obm)
        DllCall("DeleteObject", "Ptr", hFont)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc)
        
        w := NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int")
        h := NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
        return {W: w, H: h}
    }

    AnimateSlideIn() {
        reachedTarget := false
        if (this.IsBottomHalf) {
            this.CurrentY -= OSDSettings.Speed 
            if (this.CurrentY <= this.FinalY) {
                this.CurrentY := this.FinalY
                reachedTarget := true
            }
        } else {
            this.CurrentY += OSDSettings.Speed 
            if (this.CurrentY >= this.FinalY) {
                this.CurrentY := this.FinalY
                reachedTarget := true
            }
        }
        this.CurrentAlpha := Min(OSDSettings.Opacity, this.CurrentAlpha + this.AlphaStep)
        WinSetTransparent(Integer(this.CurrentAlpha), this.MyGui.Hwnd)
        DllCall("SetWindowPos", "Ptr", this.MyGui.Hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)
        
        if (reachedTarget) {
            SetTimer(this.SlideInCb, 0)
            this.State := "Visible"
            if (OSDSettings.Opacity != 255)
                WinSetTransparent(OSDSettings.Opacity, this.MyGui.Hwnd)
            else
                WinSetTransparent("", this.MyGui.Hwnd)
            
            if (this.TargetDuration > 0) {
                SetTimer(this.DestroyCb, -this.TargetDuration)
            }
        }
    }

    AnimateSlideOut() {
        reachedTarget := false
        if (this.IsBottomHalf) {
            this.CurrentY += OSDSettings.Speed 
            if (this.CurrentY >= this.StartY) {
                this.CurrentY := this.StartY
                reachedTarget := true
            }
        } else {
            this.CurrentY -= OSDSettings.Speed 
            if (this.CurrentY <= this.StartY) {
                this.CurrentY := this.StartY
                reachedTarget := true
            }
        }
        this.CurrentAlpha := Max(0, this.CurrentAlpha - this.AlphaStep)
        WinSetTransparent(Integer(this.CurrentAlpha), this.MyGui.Hwnd)
        DllCall("SetWindowPos", "Ptr", this.MyGui.Hwnd, "Ptr", -1, "Int", this.PosX, "Int", this.CurrentY, "Int", 0, "Int", 0, "UInt", 0x0051)
        
        if (reachedTarget) {
            SetTimer(this.SlideOutCb, 0)
            this.MyGui.Hide()
            this.State := "Hidden"
        }
    }

    UpdateText(newText) {
        if (this.MyGui && this.TextCtrl && (this.State == "Visible" || this.State == "SlidingIn")) {
            this.TextCtrl.Value := newText
        }
    }

    IsVisible {
        get => (this.State == "Visible" || this.State == "SlidingIn")
    }

    Destroy() {
        SetTimer(this.DestroyCb, 0) 
        
        if (this.State == "Visible" || this.State == "SlidingIn") {
            this.State := "SlidingOut"
            SetTimer(this.SlideInCb, 0)
            SetTimer(this.SlideOutCb, 5)
        } else if (this.State == "Hidden" && this.MyGui) {
            this.MyGui.Destroy()
            this.MyGui := ""
        }
    }
}