/************************************************************************
 * @description Options GUI with Spacious 2-Column Color Layout & Reset Action
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/18
 * @version 1.7.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowOSDOptionsGUI() {
    global Settings, OSDSettings, ResetOSDSettings

    ; --- STRUCTURAL BACKUPS (For Cancel and Reset actions) ---
    OriginalSettings := Settings.Clone()
    OriginalOSDSettings := OSDSettings.Clone()

    MyGuiTitle := "OSD Options"
;    MyGuiOptions := "+LastFound -SysMenu"
    MyGuiOptions := "+LastFound"

    ; Check DarkMode
    if (IsSet(CurrentActualTheme) && CurrentActualTheme == "Dark") {
        MyGui := DarkGui(MyGuiOptions, MyGuiTitle)
    } else {
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
    }

    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Expanded layout constants for maximum breathing room
    GuiWidth            := 480
    BtnWidth            := 90
    MyGui.MarginX       := 45
    MyGui.MarginY       := 35

        MyGui.Add("GroupBox", "xm y+20 w" GuiWidth - (MyGui.MarginX * 2) " h580", )

        ; 4.1. Show OSD
        optShowOSD := MyGui.Add("Checkbox", "xp+25 yp+30", "Use On Screen Display")
        optShowOSD.Value := OSDSettings.UseOSD

    ; 3.2. Theme (Auto / Light / Dark using a DropDownList)
        ThemeList := ["Auto", "Light", "Dark"]
        StartingIndex := 1
        For Index, Value in ThemeList {
            If (Value = Settings.DesiredTheme) {
                StartingIndex := Index
                Break
            }
        }
        MyGui.Add("Text", "xM+25 y+20 w160", "Theme:")
        optTheme := MyGui.AddDDL("vOSDTheme x" GuiWidth - MyGui.MarginX - 115 " yp-3 w90 Choose" . StartingIndex, ["Auto", "Light", "Dark"])


        ; 3.2. OSD Position
        PositionList := ["Top", "Bottom"]
        StartingIndex := 1
        For Index, Value in PositionList {
            If (Value = OSDSettings.Position) {
                StartingIndex := Index
                Break
            }
        }
        MyGui.Add("Text", "xM+25 y+20 w160", "Position:")
        optOSDPosition := MyGui.AddDDL("vOSDPosition x" GuiWidth - MyGui.MarginX - 115 " yp-3 w90 Choose" . StartingIndex, ["Top", "Bottom"])

        ; 4.2. OSD Speed
        MyGui.Add("Text", "xM+25 y+20 w160", "Speed (default " ResetOSDSettings.Speed "):")
        optOSDSpeed := MyGui.Add("Edit", "vOSDSpeed x" GuiWidth - MyGui.MarginX - 95 " yp-3 w70", OSDSettings.Speed)
        MyGui.Add("UpDown", "vUpDownSpeed Range1-20", OSDSettings.Speed)

        ; 4.2. OSD Duration
        MyGui.Add("Text", "xM+25 y+20 w160", "Duration (default " ResetOSDSettings.TimeOut " ms):")
        optOSDTimeout := MyGui.Add("Edit", "vOSDTimeout x" GuiWidth - MyGui.MarginX - 95 " yp-3 w70", OSDSettings.TimeOut)
        MyGui.Add("UpDown", "vUpDownTimeout Range100-5000", OSDSettings.TimeOut)

        ; 4.2. OSD Width
        MyGui.Add("Text", "xM+25 y+20 w160", "Width (default " ResetOSDSettings.Width "):")
        optOSDWidth := MyGui.Add("Edit", "vOSDSize x" GuiWidth - MyGui.MarginX - 95 " yp-3 w70", OSDSettings.Width)
        MyGui.Add("UpDown", "vUpDownSize Range100-2000", OSDSettings.Width)

        ; 4.3. OSD Font Size
        MyGui.Add("Text", "xM+25 y+20 w160", "Font Size (default " ResetOSDSettings.FontSize "):")
        optFontSize := MyGui.Add("Edit", "vFontSize x" GuiWidth - MyGui.MarginX - 95 " yp-3 w70", OSDSettings.FontSize)
        MyGui.Add("UpDown", "vUpDownFontSize Range1-50", OSDSettings.FontSize)


        ; --- COLOR PICKER GRID (2 Columns x 6 Rows) ---
        MyGui.SetFont("s" Settings.GuiFontSizeSmall)
        
        ; Column Headers for clarity
        MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 125 " y+40 w40 +Center", "Light")
        MyGui.Add("Text", "x+20 yp w40 +Center", "Dark")
        
        ; Row 1: Default Text
        MyGui.Add("Text", "xM+25 y+15 w160 h20 +0x200", "Text:")
        optColorBtn1 := MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 120 " yp w30 h22 Border vTextDefaultLight Background" OSDSettings.TextDefaultLight)
        optColorBtn7 := MyGui.Add("Text", "x+30 yp w30 h22 Border vTextDefaultDark Background" OSDSettings.TextDefaultDark)

        ; Row 2: Background
        MyGui.Add("Text", "xM+25 y+15 w160 h20 +0x200", "Background:")
        optColorBtn2 := MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 120 " yp w30 h22 Border vBgColorLight Background" OSDSettings.BgColorLight)
        optColorBtn8 := MyGui.Add("Text", "x+30 yp w30 h22 Border vBgColorDark Background" OSDSettings.BgColorDark)

        ; Row 3: Border
        MyGui.Add("Text", "xM+25 y+15 w160 h20 +0x200", "Border:")
        optColorBtn3 := MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 120 " yp w30 h22 Border vBorderColorLight Background" OSDSettings.BorderColorLight)
        optColorBtn9 := MyGui.Add("Text", "x+30 yp w30 h22 Border vBorderColorDark Background" OSDSettings.BorderColorDark)

        ; Row 4: Progress Foreground
        MyGui.Add("Text", "xM+25 y+15 w160 h20 +0x200", "Progress Fill:")
        optColorBtn4 := MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 120 " yp w30 h22 Border vProgressFgColorLight Background" OSDSettings.ProgressFgColorLight)
        optColorBtn10 := MyGui.Add("Text", "x+30 yp w30 h22 Border vProgressFgColorDark Background" OSDSettings.ProgressFgColorDark)

        ; Row 5: Progress Background
        MyGui.Add("Text", "xM+25 y+15 w160 h20 +0x200", "Progress Track:")
        optColorBtn5 := MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 120 " yp w30 h22 Border vProgressBgColorLight Background" OSDSettings.ProgressBgColorLight)
        optColorBtn11 := MyGui.Add("Text", "x+30 yp w30 h22 Border vProgressBgColorDark Background" OSDSettings.ProgressBgColorDark)

        ; Row 6: Progress Over 100
        MyGui.Add("Text", "xM+25 y+15 w160 h20 +0x200", "High Volume:")
        optColorBtn6 := MyGui.Add("Text", "x" GuiWidth - MyGui.MarginX - 120 " yp w30 h22 Border vProgressOver100Light Background" OSDSettings.ProgressOver100Light)
        optColorBtn12 := MyGui.Add("Text", "x+30 yp w30 h22 Border vProgressOver100Dark Background" OSDSettings.ProgressOver100Dark)

        MyGui.SetFont("s" Settings.GuiFontSizeMedium)
        ; -----------------------------------------------------------


    ; 6. Buttons OK, Cancel, and Reset side-by-side with breathing room
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    
    ; Recalculate horizontal centering for 3 buttons
    totalBtnWidth := (BtnWidth * 3) + 30
    startX := (GuiWidth - totalBtnWidth) // 2

    MyGui.AddButton("x" startX " y+55 w" BtnWidth " h32 Default", "&OK").OnEvent("Click", CleanDestroy)
    MyGui.AddButton("x+15 yp w" BtnWidth " h32", "&Cancel").OnEvent("Click", CancelDestroy)
    MyGui.AddButton("x+15 yp w" BtnWidth " h32", "&Reset").OnEvent("Click", ResetAction)

    ; Define control array context
    colorButtons := [optColorBtn1, optColorBtn2, optColorBtn3, optColorBtn4, optColorBtn5, optColorBtn6, 
                     optColorBtn7, optColorBtn8, optColorBtn9, optColorBtn10, optColorBtn11, optColorBtn12]

    OSDDisableEnable()

    optShowOSD.OnEvent("Click", ActionsShowOSD)
    optTheme.OnEvent("Change", ActionsOSDGeneralWait)
    optOSDPosition.OnEvent("Change", ActionsOSDGeneralWait)
    optOSDSpeed.OnEvent("Change", ActionsOSDGeneralWait)
    optOSDTimeout.OnEvent("Change", ActionsOSDGeneralWait)
    optOSDWidth.OnEvent("Change", ActionsOSDGeneralWait)
    optFontSize.OnEvent("Change", ActionsOSDGeneralWait)

    ; Bind events for the color block buttons
    for btn in colorButtons {
        btn.OnEvent("Click", ChooseColorEvent)
    }

    MyGui.OnEvent("Close", CancelDestroy)
    MyGui.OnEvent("Escape", CancelDestroy)

    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)
    MyGui.Show("w" GuiWidth)


    ActionsOSDGeneralWait(Ctrl, targetTheme := "") {
        static BoundFunc := ""
        
        if BoundFunc
            SetTimer(BoundFunc, 0)
        
        if (targetTheme = 0 || targetTheme = "") {
            targetTheme := CurrentActualTheme
        }
        
        BoundFunc := ActionsOSD.Bind(Ctrl, targetTheme)
        SetTimer(BoundFunc, -650)
    }

    ActionsOSD(Ctrl, targetTheme) {
        global OSDSettings

        if (Ctrl.Name = "OSDSize")
            OSDSettings.Width := StrReplace(Ctrl.Value, ",")
        else if (Ctrl.Name = "OSDTimeout")
            OSDSettings.TimeOut := StrReplace(Ctrl.Value, ",")
        else if (Ctrl.Name = "OSDSpeed")
            OSDSettings.Speed := StrReplace(Ctrl.Value, ",")
        else if (Ctrl.Name = "FontSize")
            OSDSettings.FontSize := Ctrl.Value
        else if (Ctrl.Name = "OSDPosition")
            OSDSettings.Position := Ctrl.Text
        else if (Ctrl.Name = "OSDTheme"){
            Settings.DesiredTheme := Ctrl.Text
            ApplyTheme(Settings.DesiredTheme)
            OSDThemeChange()
            targetTheme := CurrentActualTheme
        }

        While (IsObject(osdGui) && osdGui.Hwnd && WinVisible(osdGui.Hwnd))
            Sleep(100)
        
        osdGui.Destroy()
        
        OSDUpdateColors(targetTheme) 
        
        CreateOSD()
        ListenAndLastGainValues()
        ShowOSD(Faders[1])
    }

    ActionsShowOSD(Ctrl, *) {
        OSDSettings.UseOSD := Ctrl.Value
        OSDDisableEnable()

        if OSDSettings.UseOSD {
            OSDUpdateColors()
            CreateOSD()
            ShowOSD(Faders[1])
        } else {
            While (IsObject(osdGui) && osdGui.Hwnd && WinVisible(osdGui.Hwnd))
                Sleep(100)
            osdGui.Destroy()
        }
        ListenAndLastGainValues()
    }

    ; The Handler for picking and assigning colors dynamically
    ChooseColorEvent(ctl, info) {
        global defColor 
        
        if !IsSet(defColor)
            defColor := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

        hwnd := ctl.gui.hwnd
        currentColor := OSDSettings.%ctl.Name%
        initColor := "0x" . currentColor

        newColorRGB := ColorSelect(initColor, hwnd, &defColor, 1)
        if (newColorRGB = -1)
            return

        rgbHex := SubStr(newColorRGB, 3)
        OSDSettings.%ctl.Name% := rgbHex

        ctl.Opt("Background" rgbHex)
        DllCall("RedrawWindow", "Ptr", ctl.hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0101)
        
        targetTheme := SubStr(ctl.Name, -5) = "Light" ? "Light" : "Dark"
        
        ActionsOSDGeneralWait(ctl, targetTheme)
    }

    ; Executed ONLY when confirming with the OK button
    CleanDestroy(*) {
        OSDSettings.UseOSD          := optShowOSD.Value   
        OSDSettings.Speed           := StrReplace(optOSDSpeed.Value, ",")
        OSDSettings.TimeOut         := StrReplace(optOSDTimeout.Value, ",")
        Settings.DesiredTheme       := optTheme.Text      
        OSDSettings.Position        := optOSDPosition.Text
        OSDSettings.Width           := optOSDWidth.Value   
        OSDSettings.FontSize        := optFontSize.Value  

        MyGui.Destroy()
        RemoveGuiFromArray(MyGui)
        
        ; Save changes permanently to INI file
        SaveINI()
    }

    ; Executed on Cancel, Close (X), or Escape (Discards all changes)
    CancelDestroy(*) {
        ; Restore original active global objects from memory deep clones
        Settings := OriginalSettings
        OSDSettings := OriginalOSDSettings

        ; Apply original application theme back
        ApplyTheme(Settings.DesiredTheme)

        ; Restore preview OSD visually to original values immediately
        if (IsObject(osdGui) && osdGui.Hwnd) {
            osdGui.Destroy()
        }
        
        if OSDSettings.UseOSD {
            OSDUpdateColors(CurrentActualTheme)
            CreateOSD()
            ListenAndLastGainValues()
        }

        MyGui.Destroy()
        RemoveGuiFromArray(MyGui)
    }

    ; Executed when clicking Reset button (Restores defaults and reloads GUI controls)
    ResetAction(*) {
        ; Restore active runtime parameters from the default template configurations
        Settings := OriginalSettings.Clone()
        OSDSettings := ResetOSDSettings.Clone()

        ; Apply restored default theme
        ApplyTheme(Settings.DesiredTheme)

        ; 1. Reload standard form components
        optShowOSD.Value := OSDSettings.UseOSD
        
        ; Re-evaluate DropDownList indices safely
        for idx, val in ThemeList {
            if (val = Settings.DesiredTheme) {
                optTheme.Choose(idx)
                break
            }
        }
        for idx, val in PositionList {
            if (val = OSDSettings.Position) {
                optOSDPosition.Choose(idx)
                break
            }
        }

        optOSDSpeed.Value       := OSDSettings.Speed
        optOSDTimeout.Value     := OSDSettings.TimeOut
        optOSDWidth.Value       := OSDSettings.Width
        optFontSize.Value       := OSDSettings.FontSize

        ; 2. Reload all 12 color block backgrounds and visually repaint them immediately
        for btn in colorButtons {
            btn.Opt("Background" OSDSettings.%btn.Name%)
            DllCall("RedrawWindow", "Ptr", btn.hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0101)
        }

        ; 3. Refresh enabling/disabling state rules across the entire grid
        OSDDisableEnable()

        ; 4. Recreate the live OSD engine preview with default template values instantly
        if (IsObject(osdGui) && osdGui.Hwnd) {
            osdGui.Destroy()
        }
        
        if OSDSettings.UseOSD {
            OSDUpdateColors(CurrentActualTheme)
            CreateOSD()
            ListenAndLastGainValues()
            ShowOSD(Faders[1])
        }
    }

    OSDDisableEnable() {
        state := optShowOSD.Value
        
        For ctrlHwnd, ctrlObj in MyGui {
            if (ctrlObj.Hwnd == optShowOSD.Hwnd)
                continue
                
            ; Maintain exit and adjustment control buttons active under all conditions
            if (ctrlObj.Type == "Button" && (ctrlObj.Text == "&OK" || ctrlObj.Text == "&Cancel" || ctrlObj.Text == "&Reset"))
                continue
                
            if (ctrlObj.Name == "Strong_Title" || ctrlObj.Name == "Smooth_Version")
                continue

            ctrlObj.Enabled := state
        }
    }
}