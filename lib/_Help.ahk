/************************************************************************
 * @description Help GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/29
 * @version 1.4.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowHelpGUI() {
    MyGuiTitle := "Help"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth            := 640
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
    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "xm y+30 w" . (GuiWidth - (MyGui.MarginX * 2)), "HotKey")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Block/ unblock Internet access from any active program`nusing the shortkey defined in the tray menu.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Select from Running Programs")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Pick from curretly running process.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Select Any Program File")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Use file browser to select a program to block/unblock.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Manage Active Block Rules")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Find all currently blocked programs.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Start on Boot")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Launch this script when Windows user login.")

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w300")
    MyGui.Add("Text", "y+20 vSmooth_Disclaimer w" . (GuiWidth - (MyGui.MarginX * 2)), "It requires administrator rights.*")
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")

    ; 4. Button
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    ; 5.1 align
;        btnX := MyGui.MarginX ; left
;        btnX := (GuiWidth - BtnWidth) // 2 ; center
        btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right
;    MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", (*) => myGui.Destroy())
    MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", CleanDestroy)


    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    if IsFunctionDefined("ApplyThemeToGui") {
        %"ApplyThemeToGui"%(MyGui)
        %"WatchedGUIs"%.Push(MyGui)
    }

    MyGui.Show("w" GuiWidth)

    CleanDestroy(*) {
        if IsFunctionDefined("RemoveGuiFromArray")
            %"RemoveGuiFromArray"%(MyGui)
        if (IsSet(CurrentActualTheme) && CurrentActualTheme == "Dark") {
            %"RemoveGuiFromArray"%(MyGui)
        }
        MyGui.Destroy()
    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}