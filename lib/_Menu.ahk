/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.9.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

StartMenu() {
    local appName

    A_IconHidden := true
    A_TrayMenu.Delete()
    
    appName := HasMethod(App ?? "", "HasProp") && App.HasProp("Name") ? App.Name : A_ScriptName
    A_IconTip := appName
    
    TrayMenu                := A_TrayMenu
    TrayMenu.ClickCount     := 1
    
    try {
        if HasMethod(App ?? "", "HasProp") && App.HasProp("Icon")
            TraySetIcon(App.Icon,, true)
    }
    A_IconHidden := false
;    OnMessage(0x404, TrayIconClick)  ; WM_TRAYICON = 0x404

    TrayMenu.Add(appName, (*) => TrayMenu.Show())
    TrayMenu.Default            := appName
    TrayMenu.Disable(appName)
    TrayMenu.Add()
    TrayMenu.Add("Exit", (*) => ExitApp())
    
    MoreMenu := Menu()
    A_TrayMenu.MoreMenu := MoreMenu
    
    ; 1. Check for Dark Mode / Themes (Requires global 'Settings' object)
    if IsSet(Settings) && Settings.HasProp("DarkModeCompatible") && Settings.DarkModeCompatible {
        for theme in Settings.ThemeList {
            MoreMenu.Add(theme, ThemeHandler)
        }
        MoreMenu.Check(Settings.DesiredTheme)
        MoreMenu.Disable(Settings.DesiredTheme)
        MoreMenu.Add()
    }
    
    ; 2. Start on Boot (Self-contained, always included)
    MoreMenu.Add("Start on Boot", MenuBootHandler)
;    MoreMenu.Add()
    MoreMenu.Add("Suspend", MenuToggleSuspendHandler)
    MoreMenu.Add("Pause", MenuTogglePauseHandler)
    ;MoreMenu.Add("Restart", (*) => Reload())
    MoreMenu.Add()
    MoreMenu.Add("Explore", (*) => Run('explorer.exe /select,"' . A_ScriptFullPath . '"'))
    
    if !A_IsCompiled
        MoreMenu.Add("Edit", (*) => Run('explorer.exe /edit,"' . A_ScriptFullPath . '"'))
        ;MoreMenu.Add("Edit", (*) => Run '*edit "' . scriptPath . '"')
    
    ; 3. Check for Help GUI function
    if IsFunctionDefined("ShowHelpGUI") {
        MoreMenu.Add("Help", (*) => %"ShowHelpGUI"%())
    }
    
    ; 4. Check for About GUI function
    if IsFunctionDefined("ShowAboutGUI") {
        MoreMenu.Add("About", (*) => %"ShowAboutGUI"%())
    }
    TrayMenu.Insert("Exit", "More", MoreMenu)
    ;TrayMenu.Add("Restart", (*) => Reload())
    TrayMenu.Insert("Exit", "Restart", (*) => Reload())

    SettingsLoadStartOnBoot(appName) ? MoreMenu.Check("Start on Boot") : ""

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }

    TrayIconClick(wParam, lParam, msg, hwnd) {
        if (lParam = 0x203 || lParam = 0x201) {  ; 1 click / 2 clicks
    ;        Send("{Escape}")
    ;        Sleep(50)
    ;        if WinExist("About") {
    ;            WinActivate("About")
    ;        } else {
    ;            ShowAboutGUI()
    ;        }
            A_TrayMenu.Show()
        }
    }

    ThemeHandler(ItemName, ItemPos, MyMenu) {
        global Settings, OSDSettings
        Settings.DesiredTheme := ItemName
        try %"ApplyTheme"%(Settings.DesiredTheme)

        if HasMethod(OSDCustom ?? "", "HasProp") {
            try {
                %"OSDSettings"%.Theme := ItemName
                %"OSD"%.ApplyThemeColors()
            }
        }

        try %"SaveINI"%()

        for item in Settings.ThemeList {
            isCurrent := (item == ItemName)
            MyMenu.% isCurrent ? "Check" : "Uncheck" %(item)
            MyMenu.% isCurrent ? "Disable" : "Enable" %(item)
        }
    }

    SettingsLoadStartOnBoot(appName) {
        try {
            currentvalue := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", appName)
            return (currentvalue = '"' A_AhkPath '"')
        } catch {
            return false
        }
    }

    SettingsSaveStartOnBoot(enable, appName) {
        if enable {
            RegWrite('"' A_AhkPath '"', "REG_SZ", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", appName)
        } else {
            RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run", appName)
        }
    }

    MenuBootHandler(ItemName, ItemPos, MyMenu) {
        local appName

        appName := IsSet(App) && App.HasProp("Name") ? App.Name : A_ScriptName
        newstate := !SettingsLoadStartOnBoot(appName)
        SettingsSaveStartOnBoot(newstate, appName)
        newstate ? MyMenu.Check(ItemName) : MyMenu.Uncheck(ItemName)
    }

    MenuToggleSuspendHandler(ItemName, ItemPos, MyMenu) {
        global Settings
        Suspend(-1)
        MyMenu.ToggleCheck(ItemName)

        if (A_IsCompiled && (Settings.IsScriptPaused || A_IsSuspended))
            TraySetIcon(App.IconPaused, -207, true)
        else if (Settings.IsScriptPaused || A_IsSuspended)
            TraySetIcon(App.IconPaused, -207, true)
        else
        TraySetIcon(App.Icon,, true)

    }

    MenuTogglePauseHandler(ItemName, ItemPos, MyMenu) {
        global Settings
        Settings.IsScriptPaused := !Settings.IsScriptPaused

        if (A_IsCompiled && (Settings.IsScriptPaused || A_IsSuspended))
            TraySetIcon(App.IconPaused, -207, true)
        else if (Settings.IsScriptPaused || A_IsSuspended)
            TraySetIcon(App.IconPaused, -207, true)
        else
        TraySetIcon(App.Icon,, true)
        MyMenu.ToggleCheck(ItemName)
    }

    ; --- FIRST RUN NOTIFICATION ---
    RegKeyPath := "HKCU\Software\" . AppName
    try {
        RegRead(RegKeyPath, "FirstRun")
    } 
    catch {
        RegWrite(1, "REG_DWORD", RegKeyPath, "FirstRun")
        TrayTip(App.Name " is now active and running in your system tray.", "Welcome!", "Mute " 36)
    }
}
