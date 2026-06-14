/************************************************************************
 * @description Config&Vars
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.3.0
 ***********************************************************************/

;@region Configuration
Debug                       := false
A_ScriptName                := AppName
CurrentActualTheme          := "Light"
NameNoSpace                 := StrReplace(AppName, " ")
Global App := {
    Name:                       AppName,
    NameNoSpace:                NameNoSpace,
    NameCutted:                 AppName,
    Description:                AppDescription,
    Icon:                       A_IsCompiled ? A_ScriptFullPath : A_ScriptDir "\lib\app.ico",
    IconPaused:                 A_IsCompiled ? A_ScriptFullPath : A_ScriptDir "\lib\app_Pause.ico",
    Copyright:                  "Developed by Melo`nmelo@meloprofessional.com`n©Melo. All rights reserved.",
    Version:                    AppVersion
}

Global Settings := {
    ; General GUI
    SplashScreen:               "Banner",
    SplashScreenList:           ["Disabled", "Icon", "Banner"],
    DesiredTheme:               "Auto",
    ThemeList:                  ["Light", "Dark", "Auto"],
    DarkModeMinVer:              "10.0.17763",
    DarkModeCompatible:          false,
    GuiFontSizeSmall:           8,
    GuiFontSizeMedium:          9,
    GuiFontSizeBig:             10,
    GuiFontSizeExtraBig:        14,
    GuiFontName:                "Segoe UI",
    GuiSplashTimer:             1800,
    IsScriptPaused:             false,

; GUI Colors
    Theme: {
        Dark: {
            Bg:                 "202020", 
            TextDefault:        "CCCCCC",
            TextStrong:         "FFFFFF",
            TextSmooth:         "888888" 
        },
        Light: {
            Bg:                 "F0F0F0", 
            TextDefault:        "222222",
            TextStrong:         "000000",
            TextSmooth:         "666666" 
        }
    }
}
;@endregion

;@region INI
SaveToINI := ["Settings.DesiredTheme"] ; what to save to INI file
;SaveToINI.Push("Settings.SplashScreen")     ; add more to INI file
RegisterArrayItems(SaveToINI)
LoadINI()
;@endregion