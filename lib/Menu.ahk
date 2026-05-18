#Requires AutoHotkey v2.0

StartMenu() {
    A_IconHidden := true
    A_TrayMenu.Delete()
    A_IconTip               := App.Name
    TrayMenu                := A_TrayMenu
    TrayMenu.ClickCount     := 1
    try TraySetIcon(App.Icon, , true)
    A_IconHidden := false

    TrayMenu.Add("Mouse Wheel to VM", (*) => TrayMenu.Show())
    TrayMenu.Default            := "Mouse Wheel to VM"
    TrayMenu.Disable("Mouse Wheel to VM")

    TrayMenu.Add("Voicemeeter", (*) => voicemeeter.command.show())
    TrayMenu.Add("Restart Audio Engine", (*) => voicemeeter.command.restart())
    TrayMenu.Add("Macro Buttons", (*) => voicemeeter.macrobutton.Show())
    TrayMenu.Add("Restart All", (*) => RestartAll())
    TrayMenu.Add()
    TrayMenu.Add("Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Add("Volume Mixer", (*) => Run("sndvol.exe"))

    TrayMenu.Add()
    TrayMenu.Add("Restart", (*) => Reload())
    TrayMenu.Add()
    TrayMenu.Add("Exit", (*) => ExitApp())

    MoreMenu := Menu()
    TrayMenu.Insert("Restart", "More", MoreMenu)
    MoreMenu.Add("Settings...", (*) => ShowOptionsGUI())
    MoreMenu.Add("OSD Options...", (*) => ShowOSDOptionsGUI())
    MoreMenu.Add()
    MoreMenu.Add("Light", ThemeHandler)
    MoreMenu.Add("Dark", ThemeHandler)
    MoreMenu.Add("Auto", ThemeHandler)
    MoreMenu.Add()
    MoreMenu.Add("Start on Boot", MenuBootHandler)
    MoreMenu.Add()
    MoreMenu.Add("Explore", (*) => Run('explorer.exe /select,"' . A_ScriptFullPath . '"'))
    if !A_IsCompiled
        MoreMenu.Add("Edit", (*) => Run('explorer.exe /edit,"' . A_ScriptFullPath . '"'))
    MoreMenu.Add("GitHub Repo", Repo)
    MoreMenu.Add("About", (*) => ShowAboutGUI())

    SettingsLoadStartOnBoot() ? MoreMenu.Check("Start on Boot") : ""

    switch Settings.DesiredTheme {
        case "Light":
            {
                MoreMenu.Check("Light")
                MoreMenu.Disable("Light")
            }
        case "Dark":
            {
                MoreMenu.Check("Dark")
                MoreMenu.Disable("Dark")
            }
        case "Auto":
            {
                MoreMenu.Check("Auto")
                MoreMenu.Disable("Auto")
            }
    }

}

ThemeHandler(ItemName, ItemPos, MyMenu) {
    global Settings

    Settings.DesiredTheme := ItemName
    ApplyTheme(Settings.DesiredTheme)
    if OSDSettings.UseOSD
        OSDThemeChange()
    SaveINI()
    MyMenu.Uncheck("Light")
    MyMenu.Uncheck("Dark")
    MyMenu.Uncheck("Auto")
    MyMenu.Enable("Light")
    MyMenu.Enable("Dark")
    MyMenu.Enable("Auto")
    MyMenu.Check(ItemName)
    MyMenu.Disable(ItemName)
}

MenuBootHandler(ItemName, ItemPos, MyMenu) {
    newstate := !SettingsLoadStartOnBoot()
    SettingsSaveStartOnBoot(newstate)
    newstate ? MyMenu.Check(ItemName) : MyMenu.Uncheck(ItemName)
}

SettingsLoadStartOnBoot() {
    try {
        currentvalue := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", App.Name)
        return (currentvalue = '"' A_AhkPath '"')
    } catch {
        return false
    }
}

SettingsSaveStartOnBoot(enable) {
    if enable {
        RegWrite('"' A_AhkPath '"', "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", App.Name)
    } else {
        RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", App.Name)
    }
}

Repo(*) {
    Run("https://github.com/Melo-Professional/Mouse-Wheel-to-Voicemeeter")
}