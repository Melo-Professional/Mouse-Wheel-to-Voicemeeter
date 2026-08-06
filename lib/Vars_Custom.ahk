/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/26
 * @version 1.0.1
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.Github := "https://github.com/Melo-Professional/Mouse-Wheel-to-Voicemeeter"
if (App.HasOwnProp("Github")  && App.Github != "" && App.Github != "https://github.com/Melo-Professional/") {
	App.UpdateAuto := true
	App.UpdateFrequencyDays := 3
	App.UpdateLastCheck := ""
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
}

Global General := {
    BTDetect:                   true,
    WheelSpeed:                 10,
    gainStepsMin:               2,
    gainStepsMax:               20
}

; Define the Logical IDs of MacroButtons used to mute/unmute each VoiceMeeter strip.
; if you dont have, put MacroButtonMuteUnmuteVirtualInput := []
; IMPORTANT: The order MUST be:
; [1] VoiceMeeter Input
; [2] VoiceMeeter AUX
; [3] VoiceMeeter VAIO3

Global MacroButtonMuteUnmuteVirtualInput := [
                            23, ; [1] VoiceMeeter Input strip
                            30, ; [2] VoiceMeeter AUX strip
                            45  ; [3] VoiceMeeter VAIO3 strip
]

Global OSDSettings := {
    DWMMinVer:                  "10.0.22000",
    DWMCompatible:              false,
    UseOSD:                     true,
    Width:                      200,        ; valor correto
    FontSize:                   9,
    TimeOut:                    1800,       ; duration of OSD in milliseconds
    Speed:                      4,          ; Pixels moved per tick (Increase for faster animations)
    Position:                   "Bottom",   ; Bottom / Top
    EdgeDistance:               60,         ; OSD distance from screen edge
    SlideDistance:              23,          ; Set your preferred slide distance here
    FontName:                   "Segoe UI",
    FontWeight:                 1000,
    MarginX:                    16,
    MarginY:                    12,
    Opacity:                    255,
    ColoredBorder:              true,
    RoundedCorners:             10,
    ProgressMaxValue:           100,

    ; Theme
    Theme:                      "Light", ; "Light" / "Dark" / "Auto"

    ; lightmode
    TextDefaultLight:           "5a5555",
    BgColorLight:               "F5F9FB",
    BgColorLight:               "F3F3F3",
    BorderColorLight:           "ffffff",
    ProgressFgColorLight:       "0067C0",
    ProgressFgColorLight:       "0078D7",
    ProgressFgColorLight:       "005A9E",
    ProgressBgColorLight:       "EDF1F2", ; HEX or "transparent"
    ProgressBgColorLight:       "E5E5E5", ; HEX or "transparent"
    ProgressOver100Light:       "FF5555",

    ; darkmode
    TextDefaultDark:            "d8d8d8",
    BgColorDark:                "272525",
    BgColorDark:                "1E1E1E",
    BorderColorDark:            "272525",
    ProgressFgColorDark:        "4CC2FF",
    ProgressFgColorDark:        "0078D7",
    ProgressBgColorDark:        "333333", ; HEX or "transparent"
    ProgressOver100Dark:        "FF5555",

}
global LastGainValues := []

ResetSettings       := Settings.Clone()
ResetOSDSettings    := OSDSettings.Clone()
ResetGeneral        := General.Clone()

App.NameCutted := "Mouse Wheel`nto Voicemeeter"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion

;@region INI
SaveToINI.Push("Settings.SplashScreen", "Settings.BTDetect",
            "Settings.WheelSpeed", "OSDSettings.UseOSD", "OSDSettings.TimeOut",
            "OSDSettings.Width", "OSDSettings.FontSize", "OSDSettings.Position", 
            "OSDSettings.TextDefaultLight", "OSDSettings.BgColorLight", "OSDSettings.BorderColorLight",
            "OSDSettings.ProgressFgColorLight", "OSDSettings.ProgressBgColorLight", "OSDSettings.ProgressOver100Light", 
            "OSDSettings.TextDefaultDark", "OSDSettings.BgColorDark", "OSDSettings.BorderColorDark", 
            "OSDSettings.ProgressFgColorDark", "OSDSettings.ProgressBgColorDark", "OSDSettings.ProgressOver100Dark",
            "OSDSettings.Speed", "General.BTDetect", "General.WheelSpeed",
            "General.gainStepsMin", "General.gainStepsMax"
)
RegisterArrayItems(SaveToINI)
LoadINI()
;@endregion