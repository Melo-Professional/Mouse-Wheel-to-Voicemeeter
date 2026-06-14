/************************************************************************
 * @description Splash Screen
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/13
 * @version 1.8.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

/*
SplashScreen("Banner", false)       ; show banner and wait
sleep(5000)
SplashScreen()                      ; shows default / destroys
SplashScreen("Icon")                ; show icon and destroys
SplashScreen("Banner")                ; show icon and destroys
*/

/**
 * @description {@link SplashScreen|SplashScreen.ahk}
 * Displays a Splashscreen with current App.Icon, App.Name and App.Description
 * @returns {(String)}
 * An empty string is always returned.
 * @example <caption>Display SplashScreen with auto destroy</caption>  
 * SplashScreen()
 * @example <caption>Display SplashScreen and later destroys</caption>  
 * SplashScreen(false)
 * <Your script goes here>
 * SplashScreen()
 */
SplashScreen(type := Settings.SplashScreen, timeauto := true) {
    static running := false
    static desiredsplash := type

    splashMap := Map(
        "Icon",   SplashIcon,
        "Banner", SplashBanner
    )

    if splashMap.Has(desiredsplash) {
        ;tooltip(desiredsplash)
        splashObj := splashMap[desiredsplash]
        destroySplash := () => (splashObj.Destroy(), running := false)
        if !running {
            splashObj.Show()
            running := true
            if (timeauto == true) {
                SetTimer(destroySplash, -Settings.GuiSplashTimer)
            }
        } else {
            splashObj.Destroy()
            running := false
            ;if (time == "auto") {
                SetTimer(destroySplash, 0) 
            ;}
        }
    }
}

/**
 * @description {@link SplashBanner|SplashBanner.ahk}
 * Displays a Splashscreen with current App.Icon, App.Name and App.Description
 * @returns {(String)}
 * An empty string is always returned.
 * @example <caption>Display the GUI</caption>  
 * SplashBanner.Show()
 * @example <caption>Destroy the GUI</caption>  
 * SplashBanner.Destroy()
 */
class SplashBanner {
    static GuiObj := 0
    static StartTime := 0
    static OriginalClassStyle := 0

    static Show() {
        this.StartTime := A_TickCount
        Scale := A_ScreenDPI / 96

        ; -------------------------------------------------------------------
        ; 1. CONSTRUCT MAIN GUI
        ; -------------------------------------------------------------------
        MyGuiTitle := "SplahScreen"
        MyGuiOptions := "-Caption +AlwaysOnTop +ToolWindow +E0x20 -DPIScale"
        this.GuiObj := Gui(MyGuiOptions, MyGuiTitle)
        hWnd := this.GuiObj.Hwnd
        
        SplashWidth := Round(400 * Scale)
        SplashRoundCorners := Round(40 * Scale)
        IconSize := Round(50 * Scale)
        
        this.GuiObj.SetFont("s" Settings.GuiFontSizeExtraBig " w1000", Settings.GuiFontName)
        if App.Name = App.NameCutted
            this.GuiObj.Add("Text", "Center vStrong_Title w" SplashWidth " x0 y" Round(70 * Scale), App.Name)
        else
            this.GuiObj.Add("Text", "Center vStrong_Title w" SplashWidth " x0 y" Round(62 * Scale), App.NameCutted)

        this.GuiObj.SetFont("s" Settings.GuiFontSizeSmall " w400")
        this.GuiObj.Add("Text", "Center vSmooth_Version y+2 w" SplashWidth, "Version " App.Version)

        try this.GuiObj.Add("Picture", "x" Round(35 * Scale) " y" Round(63 * Scale) " w" IconSize " h" IconSize, App.Icon)

        this.GuiObj.MarginY := 30
        myPrg := this.GuiObj.Add("Progress", "w" SplashWidth -(Round(70 * Scale)) " x" Round(35 * Scale) " y+" Round(30 * Scale) " h" Round(5 * Scale) " Smooth +0x00000008")
        SendMessage(0x040A, 1, 20, myPrg.Hwnd)

        if IsFunctionDefined("ApplyThemeToGui") {
            %"ApplyThemeToGui"%(this.GuiObj)
        }

        this.GuiObj.Show("w" SplashWidth " xCenter yCenter Hide")
        this.GuiObj.GetPos(, , &guiWidth, &guiHeight)
        WinSetRegion("0-0 w" guiWidth " h" guiHeight " r" SplashRoundCorners "-" SplashRoundCorners, hWnd)

        ; -------------------------------------------------------------------
        ; 2. INJECT CLASS SHADOW & SAVE ORIGINAL
        ; -------------------------------------------------------------------
        GCL_STYLE := -26
        CS_DROPSHADOW := 0x00020000
        
        ; Save the original style before modifying it
        this.OriginalClassStyle := DllCall(A_PtrSize = 8 ? "user32\GetClassLongPtr" : "user32\GetClassLong", "Ptr", hWnd, "Int", GCL_STYLE, "Ptr")
        
        ; Apply the new style containing the shadow flag
        DllCall(A_PtrSize = 8 ? "user32\SetClassLongPtr" : "user32\SetClassLong", "Ptr", hWnd, "Int", GCL_STYLE, "Ptr", this.OriginalClassStyle | CS_DROPSHADOW, "Ptr")

        ; -------------------------------------------------------------------
        ; 3. DISPLAY WINDOW
        ; -------------------------------------------------------------------
        ;sleep(200)
        this.GuiObj.Show("NoActivate")

        ; WINDOWS 10 FIX: Forces the OS to re-evaluate the style properties 
        ; and draw the drop shadow immediately without changing window dimensions.
        ; SWP_NOMOVE(0x2) | SWP_NOSIZE(0x1) | SWP_NOZORDER(0x4) | SWP_FRAMECHANGED(0x20) = 0x0027
        DllCall("user32\SetWindowPos", "Ptr", hWnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027)

        ; Restore the original window class style
        if (this.OriginalClassStyle !== 0) {
            DllCall(A_PtrSize = 8 ? "user32\SetClassLongPtr" : "user32\SetClassLong", "Ptr", hWnd, "Int", -26, "Ptr", this.OriginalClassStyle, "Ptr")
            this.OriginalClassStyle := 0
        }

        IsFunctionDefined(Name) {
            try return HasMethod(%Name%)
            return false
        }
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
        this.GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        this.GuiObj.BackColor := "070707" 
        this.GuiObj.Add("Picture", "x0 y0 w" IconSize " h" IconSize, App.Icon)
        this.GuiObj.Show("w" IconSize " h" IconSize " Hide")
        WinSetTransColor("070707 255", this.GuiObj.Hwnd)
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