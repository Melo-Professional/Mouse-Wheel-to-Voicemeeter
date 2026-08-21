/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/26
 * @version 1.3.2
 ***********************************************************************/

#Requires AutoHotkey v2.0

Menu_Custom() {

    TrayMenu := A_TrayMenu
    MoreMenu := TrayMenu.HasProp("MoreMenu") ? TrayMenu.MoreMenu : ""

    TrayMenu.Rename(app.Name, "Connecting to Voicemeeter")

    TrayMenu.Insert("More", "Voicemeeter", (*) => voicemeeter.command.show())
    TrayMenu.Insert("More", "Restart Audio Engine", (*) => voicemeeter.command.restart())
    TrayMenu.Insert("More", "Macro Buttons", (*) => voicemeeter.macrobutton.Show())
    TrayMenu.Insert("More", "Restart All", (*) => RestartAll())
    TrayMenu.Insert("More")
    TrayMenu.Insert("More", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Insert("More", "Volume Mixer Classic", (*) => Run("sndvol.exe"))
    TrayMenu.Insert("More", "Volume Mixer Modern", (*) => Run("ms-settings:apps-volume"))
    TrayMenu.Insert("More")


    MoreMenu.Insert("1&", "Settings...", (*) => ShowOptionsGUI())
    MoreMenu.Insert("2&", "OSD Options...", (*) => ShowOSDOptionsGUI())
    MoreMenu.Insert("3&")

    ; Custom items
/*
    ; INSERT AT POSITION
    TrayMenu.Insert("3&", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Insert("4&", "Volume Mixer", (*) => Run("sndvol.exe"))
    TrayMenu.Insert("5&")
 */

    ; INSERT OVER 'More'
;    TrayMenu.Insert("More", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
;    TrayMenu.Insert("More", "Volume Mixer", (*) => Run("sndvol.exe"))
;    TrayMenu.Insert("More")

    ; Clean up Suspend and Pause
;    if (MoreMenu != "") {
;    try MoreMenu.Delete("4&")
;    try MoreMenu.Delete("Suspend")
;    try MoreMenu.Delete("Pause")
;    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

;A_TrayMenu.Delete()

