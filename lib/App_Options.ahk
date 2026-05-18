/************************************************************************
 * @description Help GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/14
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowOptionsGUI() {
    global Settings, ResetSettings

    MyGuiTitle := "Options"
;    MyGuiOptions := "+LastFound +AlwaysOnTop -MinimizeBox -MaximizeBox"
    MyGuiOptions := "+LastFound -SysMenu"

    ; Check DarkMode
    if (IsSet(CurrentActualTheme) && CurrentActualTheme == "Dark") {
        MyGui := DarkGui(MyGuiOptions, MyGuiTitle)
    } else {
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
    }

    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth            := 420
    BtnWidth            := 80
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30



    ; 1. Icon
    try {
        MyGui.Add("Picture", "w32 h32", App.Icon)
    } catch {
        MyGui.SetFont("s15 w500")
        MyGui.Add("Text", "w32 h32", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeBig " w700")
    MyGui.Add("Text", "x+15 y28 vStrong_Title", App.Name)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)


    ; 3. Content
    ; 3.1. SplashScreen
            SplashScreenList := ["Banner", "Icon", "Disabled"]
            StartingIndex := 1
            For Index, Value in SplashScreenList {
                If (Value = Settings.SplashScreen) {
                    StartingIndex := Index
                    Break
                }
            }

            MyGui.Add("Text", "xm y+55 w60", "SplashScreen:")
            optSplash := MyGui.AddDDL("x" GuiWidth - MyGui.MarginX - 80 " yp-3 w80 Choose" . StartingIndex, ["Banner", "Icon", "Disabled"])

    ; 3.2. Theme (Auto / Light / Dark using a DropDownList)
            ThemeList := ["Auto", "Light", "Dark"]
            StartingIndex := 1
            For Index, Value in ThemeList {
                If (Value = Settings.DesiredTheme) {
                    StartingIndex := Index
                    Break
                }
            }

            MyGui.Add("Text", "xm y+35 w60", "Theme:")
            optTheme := MyGui.AddDDL("x" GuiWidth - MyGui.MarginX - 80 " yp-3 w80 Choose" . StartingIndex, ["Auto", "Light", "Dark"])

    ; 3.3. Wheel Speed
            MyGui.Add("Text", "xm y+35 w160", "Wheel Speed (default " ResetSettings.WheelSpeed "):")
            optWheelSpeed := MyGui.Add("Edit", "x" GuiWidth - MyGui.MarginX - 60 " yp-3 w60", Settings.WheelSpeed)
            MyGui.Add("UpDown", "Range1-20", Settings.WheelSpeed)


    ; 5. BlueTooth
            optBT := MyGui.Add("Checkbox", "xm y+50 w220", "Auto detect Bluetooth connection")
            optBT.Value := Settings.BTDetect

    ; 6. Button OK
            MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
            ; 6.1 align
        ;        btnX := MyGui.MarginX ; left
                btnX := (GuiWidth - BtnWidth) // 2 ; center
        ;        btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right
            MyGui.AddButton("x" btnX " y+45 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", CleanDestroy)


    optSplash.OnEvent("Change", ActionsSplash)
    optTheme.OnEvent("Change", ActionsTheme)
    optWheelSpeed.OnEvent("Change", ActionsWheelSpeed)
    optBT.OnEvent("Click", ActionsBT)

    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)
    MyGui.Show("w" GuiWidth)

    ActionsSplash(Ctrl, *) {
        switch Ctrl.Text {
            case "Icon": (
                    SplashIcon.Show()
                    SplashIcon.Destroy()
                )
            case "Banner": (
                    Splash.Show()
                    Splash.Destroy()
                )
        }
        Settings.SplashScreen       := optSplash.Text
        ;SaveINI()
    }

    ActionsTheme(Ctrl, *) {
        Settings.DesiredTheme := Ctrl.Text
        ApplyTheme(Settings.DesiredTheme)
        if OSDSettings.UseOSD
            OSDThemeChange()
        ;SaveINI()
    }

    ActionsWheelSpeed(Ctrl, *) {
        Settings.WheelSpeed := Ctrl.Value
    }

    ActionsBT(*) {
        Settings.BTDetect := optBT.Value
        BT_Toggle()
        ;SaveINI()
    }

    CleanDestroy(*) {
        ; Extract the values chosen by the user
        Settings.SplashScreen       := optSplash.Text
        Settings.DesiredTheme       := optTheme.Text      
        Settings.WheelSpeed         := optWheelSpeed.Value
        Settings.BTDetect           := optBT.Value        

        MyGui.Destroy()

        RemoveGuiFromArray(MyGui)
        SaveINI()

    }
}