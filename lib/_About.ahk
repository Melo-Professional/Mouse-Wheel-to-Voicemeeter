/************************************************************************
 * @description About GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/13
 * @version 1.4.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowAboutGUI() {
    MyGuiTitle := "About"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)

    ; Define layout constants
    GuiWidth            := 460
    BtnWidth            := 80
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30

    ; 1. Icon
    try {
        MyGui.Add("Picture", "w64 h-1", App.Icon)
    } catch {
        MyGui.SetFont("s22 w500")
        MyGui.Add("Text", "w64 h64", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeExtraBig " w700")
    if App.Name = App.NameCutted
        MyGui.Add("Text", "x+15 y40 vStrong_Title", App.Name)
    else
        MyGui.Add("Text", "x+15 y28 vStrong_Title", App.NameCutted)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)

    ; 3. Description
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w400")
    MyGui.Add("Text", "xm y+50 w" . (GuiWidth - (MyGui.MarginX *2)), App.Description)

    ; 4. Credits / Copyright
    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "xm y+20 vSmooth_Credits", App.Copyright)

    ; 5. Button
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    ; 5.1 align
;        btnX := MyGui.MarginX ; left
;        btnX := (GuiWidth - BtnWidth) // 2 ; center
    btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right
    MyGui.AddButton("x" (GuiWidth - MyGui.MarginX - BtnWidth) " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", CleanDestroy)

    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    if IsFunctionDefined("ApplyThemeToGui") {
        %"ApplyThemeToGui"%(MyGui)
        %"WatchedGUIs"%.Push(MyGui)
    }

    MyGui.Show()
    CleanDestroy(*) {
        if IsFunctionDefined("RemoveGuiFromArray")
            %"RemoveGuiFromArray"%(MyGui)
         MyGui.Destroy()
    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

