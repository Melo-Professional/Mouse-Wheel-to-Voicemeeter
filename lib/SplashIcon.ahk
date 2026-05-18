/************************************************************************
 * @description Splash Icon
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/14
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

/**
 * @description {@link SplashIcon|SplashIcon.ahk}
 * Displays a Splashscreen with current App.Icon
 * @returns {(String)}
 * An empty string is always returned.
 * @example <caption>Display the GUI</caption>  
 * SplashIcon.Show()
 * @example <caption>Destroy the GUI</caption>  
 * SplashIcon.Destroy()
 */
class SplashIcon {
    static GuiObj := 0
    static StartTime := 0

    static Show() {
        this.StartTime := A_TickCount
            
    IconSize := 128
    TransColor := "ABCDEF"

    this.GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
    this.GuiObj.BackColor := TransColor
    this.GuiObj.Add("Picture", "x0 y0 w" IconSize " h" IconSize, App.Icon)
    WinSetTransColor(TransColor, this.GuiObj)

    this.GuiObj.Show("NoActivate")

}

    static Destroy() {
        Elapsed := A_TickCount - this.StartTime
        
        if (Elapsed < Settings.GuiSplashTimer) {
            SetTimer(() => this.Destroy(), -(Settings.GuiSplashTimer - Elapsed))
            return
        }

        if (this.GuiObj !== 0) {
            this.GuiObj.Destroy()
            this.GuiObj := 0
        }
    }
}