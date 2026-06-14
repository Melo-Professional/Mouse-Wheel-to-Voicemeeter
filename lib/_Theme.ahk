/************************************************************************
 * @description Theme Library to apply light / dark / auto modes 
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.9.0
 ***********************************************************************/

#Requires AutoHotkey v2.0
;#Warn Unreachable, Off

global WatchedGUIs := []
;global CurrentActualTheme := ""
Settings.DarkModeCompatible := (VerCompare(A_OSVersion, Settings.DarkModeMinVer) >= 0)
ApplyTheme()

; --- New GUIs Logic's ---
HowtoCreateMyGui() {
    MyGuiTitle := "About"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
 
    ; ---- GUI Content
    MyGui.Add("Text",, "Current Theme: " . CurrentActualTheme)
    ;----------------
 
    MyGui.AddButton("h30 Default", "&OK").OnEvent("Click", CleanDestroy)
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)
    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)
    MyGui.Show()
    CleanDestroy(*) {
          RemoveGuiFromArray(MyGui)
          MyGui.Destroy()
       }
 
    return MyGui
}

ApplyThemeToGui(guiObj) {
    if !Settings.DarkModeCompatible
        return    

    colors := Settings.Theme.%CurrentActualTheme%
    isDark := (CurrentActualTheme == "Dark")

    ; --- Color Conversion (with fallback) ---
    bgBGR   := HexToBGR(colors.Bg)
    ctrlBGR := HexToBGR(colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg)
    textBGR := HexToBGR(colors.TextDefault)

    ; --- Dark Mode System Setup ---
    static uxtheme := DllCall("GetModuleHandle", "Str", "uxtheme.dll", "Ptr")
    static SetPreferredAppMode := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
    static AllowDarkModeForWindow := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 133, "Ptr")
    static FlushMenuThemes := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")

    if (SetPreferredAppMode) {
        DllCall(SetPreferredAppMode, "Int", isDark ? 2 : 0)
    }
    DllCall(AllowDarkModeForWindow, "Ptr", guiObj.Hwnd, "UInt", isDark)
    DllCall(FlushMenuThemes)

    ; --- Title Bar ---
    DWMWA := (VerCompare(A_OSVersion, "10.0.18985") >= 0) ? 20 : 19
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.Hwnd, "int", DWMWA, "int*", isDark, "int", 4)

    guiObj.BackColor := colors.Bg

    ; --- WM_CTLCOLORLISTBOX Handler (FIXED: Toggles cleanly between modes) ---
    static PrevOnCtlBound := 0
    if (PrevOnCtlBound) {
        OnMessage(0x0134, PrevOnCtlBound, 0) ; Disables the old custom drawing handle
        PrevOnCtlBound := 0
    }

    if (isDark) {
        OnCtlBound := OnCtlColorListbox.Bind(ctrlBGR, textBGR)
        OnMessage(0x0134, OnCtlBound, -1)
        PrevOnCtlBound := OnCtlBound
    }

    ; --- Apply Theme to Controls ---
    for _, ctrlObj in guiObj {
        try {

            ; --- BYPASS CHECK ---
            ; If the control has a name containing "Color" or "Btn", skip automatic recoloring
            if (ctrlObj.HasOwnProp("BypassTheme") && ctrlObj.BypassTheme)
                continue

            themeStr := isDark ? "DarkMode_DarkTheme" : "Explorer"

            DllCall(AllowDarkModeForWindow, "Ptr", ctrlObj.Hwnd, "UInt", isDark)
            DllCall("uxtheme.dll\SetWindowTheme", "ptr", ctrlObj.Hwnd, "str", themeStr, "ptr", 0)

            switch ctrlObj.Type {
                case "Text", "Checkbox", "Radio":
                    if (InStr(ctrlObj.Name, "Title") || InStr(ctrlObj.Name, "Strong"))
                        ctrlObj.Opt("c" . colors.TextStrong)
                    else if (InStr(ctrlObj.Name, "Footer") || InStr(ctrlObj.Name, "Smooth"))
                        ctrlObj.Opt("c" . colors.TextSmooth)
                    else
                        ctrlObj.Opt("c" . colors.TextDefault)

                    if (ctrlObj.Type = "Text")
                        ctrlObj.Opt("+Background" . colors.Bg)

                case "Edit", "ListBox", "ComboBox", "DDL":
                    ctrlBg := colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg
                    ctrlObj.Opt("+Background" . ctrlBg . " c" . colors.TextDefault)

                    if (ctrlObj.Type = "ComboBox" || ctrlObj.Type = "DDL") {
                        listHwnd := GetComboListHwnd(ctrlObj)
                        if (listHwnd) {
                            DllCall(AllowDarkModeForWindow, "Ptr", listHwnd, "UInt", isDark)
                            DllCall("uxtheme.dll\SetWindowTheme", "ptr", listHwnd, "str", themeStr, "ptr", 0)
                        }
                    }

                case "ListView":
                    ctrlBg := colors.HasOwnProp("Ctrl") ? colors.Ctrl : colors.Bg
                    ctrlObj.Opt("+Background" . ctrlBg . " c" . colors.TextDefault)
                    ctrlObj.Opt("-E0x200")

                    hdrHwnd := SendMessage(0x101F, 0, 0, ctrlObj)
                    if (hdrHwnd) {
                        DllCall(AllowDarkModeForWindow, "Ptr", hdrHwnd, "UInt", isDark)
                        DllCall("uxtheme.dll\SetWindowTheme", "ptr", hdrHwnd, "str", themeStr, "ptr", 0)
                    }
                    SetListViewHeaderSubclass(ctrlObj.Hwnd, textBGR)

                case "Button":
                    ctrlObj.Opt("+Background" . colors.Bg)

                case "Progress":
                    ctrlObj.Opt("+Background" . colors.Bg)
            }

            PostMessage(0x0128, 0x00010001, 0, ctrlObj.Hwnd)
            ctrlObj.Redraw()
        }
    }
}

; ========================== HELPERS ==========================

HexToBGR(hex) {
    if (hex = "")
        return 0
    num := (SubStr(hex, 1, 2) = "0x") ? Integer(hex) : Integer("0x" . StrReplace(hex, "#"))
    return ((num & 0xFF) << 16) | (num & 0xFF00) | ((num >> 16) & 0xFF)
}

GetComboListHwnd(Ctrl) {
    static CBISize := 40 + (A_PtrSize * 3)
    CBI := Buffer(CBISize, 0)
    NumPut("UInt", CBISize, CBI)
    if DllCall("GetComboBoxInfo", "Ptr", Ctrl.Hwnd, "Ptr", CBI)
        return NumGet(CBI, 40 + (A_PtrSize*2), "UInt")
    return 0
}

OnCtlColorListbox(ctrlBGR, textBGR, wParam, lParam, Msg, Hwnd) {
    Critical(-1)
    if !GuiCtrlFromHwnd(Hwnd) {  ; Matches the orphan Dropdown popup menu targets
        DllCall("SetTextColor", "Ptr", wParam, "UInt", textBGR)
        DllCall("SetBkColor",   "Ptr", wParam, "UInt", ctrlBGR)
        DllCall("SetDCBrushColor", "Ptr", wParam, "UInt", ctrlBGR)
        return DllCall("GetStockObject", "Int", 18, "Ptr") ; DC_BRUSH
    }
    return 0
}

SetListViewHeaderSubclass(hwnd, textColor) {
    static Subclassed := Map()
    static pProc := CallbackCreate(ListViewHeaderProc, , 6)

    if Subclassed.Has(hwnd) {
        DllCall("RemoveWindowSubclass", "Ptr", hwnd, "Ptr", Subclassed[hwnd], "Ptr", hwnd)
    }

    if DllCall("SetWindowSubclass", "Ptr", hwnd, "Ptr", pProc, "Ptr", hwnd, "Ptr", textColor) {
        Subclassed[hwnd] := pProc
    }
}

ListViewHeaderProc(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData) {
    Critical(-1)

    if (uMsg = 0x004E) {  ; WM_NOTIFY
        if (NumGet(lParam, A_PtrSize*2, "Int") = -12) { ; NM_CUSTOMDRAW
            stage := NumGet(lParam, A_PtrSize*3, "UInt")
            hCtrl := NumGet(lParam, "Ptr")

            if (WinGetClass(hCtrl) = "SysHeader32") {
                if (stage = 0x00000001)      ; CDDS_PREPAINT
                    return 0x20              ; CDRF_NOTIFYITEMDRAW
                if (stage = 0x00010001) {    ; CDDS_ITEMPREPAINT
                    hdc := NumGet(lParam, A_PtrSize*4, "Ptr")
                    DllCall("SetTextColor", "Ptr", hdc, "UInt", dwRefData)
                    return 0
                }
            }
        }
    }
    else if (uMsg = 0x0002) { ; WM_DESTROY
        DllCall("RemoveWindowSubclass", "Ptr", hWnd, "Ptr", uIdSubclass, "Ptr", hWnd)
    }

    return DllCall("DefSubclassProc", "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}

SetDarkTheme(hwnd, mode, isDark) {
    static AllowDarkModeForWindow := DllCall("GetProcAddress", "Ptr", 
           DllCall("GetModuleHandle", "Str", "uxtheme.dll", "Ptr"), "Ptr", 133, "Ptr")
    
    hwnd := IsObject(hwnd) ? hwnd.Hwnd : hwnd
    if (AllowDarkModeForWindow)
        DllCall(AllowDarkModeForWindow, "ptr", hwnd, "uint", isDark ? 1 : 0)
    DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "str", mode, "ptr", 0)
    SendMessage(0x031A, 0, 0, hwnd)  ; WM_THEMECHANGED
}

RemoveGuiFromArray(guiObj, *) {
   global WatchedGUIs
    for index, obj in WatchedGUIs {
        if (obj == guiObj) {
            WatchedGUIs.RemoveAt(index)
            return true
        }
    }
    return false
}

; --- Theme Management ---

ApplyTheme(ThemeMode := Settings.DesiredTheme) {
   global CurrentActualTheme

    if !Settings.DarkModeCompatible
        return    

    Settings.DesiredTheme := ThemeMode
    
    if (ThemeMode == "Auto") {
        OnMessage(0x1A, WindowsThemeChanged)
        CurrentActualTheme := GetWindowsTheme()
    } else {
        OnMessage(0x1A, WindowsThemeChanged, 0)
        CurrentActualTheme := ThemeMode
    }
    
    modeInt := (CurrentActualTheme == "Dark") ? 2 : 3
    LightDarkColorMode(modeInt)
    
    RefreshAllUIs()
}

WindowsThemeChanged(wParam, lParam, msg, hwnd) {
   global CurrentActualTheme

    if (Settings.DesiredTheme == "Auto") {
        newTheme := GetWindowsTheme()
        if (newTheme != CurrentActualTheme) {
            CurrentActualTheme := newTheme
            ApplyTheme("Auto")
        }
    }
}

RefreshAllUIs() {
   global WatchedGUIs

    if !Settings.DarkModeCompatible
        return    


    ;StartMenu()
    
    i := WatchedGUIs.Length
    while (i > 0) {
        guiObj := WatchedGUIs[i]
        
        try {
            if !WinExist(guiObj.Hwnd) {
                WatchedGUIs.RemoveAt(i)
            } else {
                ApplyThemeToGui(guiObj)
            }
        } catch {
            WatchedGUIs.RemoveAt(i)
        }
        i--
    }
}

GetWindowsTheme() {
    res := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    return (res == 0) ? "Dark" : "Light"
}

; Menu Theme
/**
 * @description {@link LightDarkColorMode|Dark.ahk}
 * Apply light/ dark mode to menu / main window.
 * @param {(String)} [Text]
 * @param {(String)} [Title]
 * @param {"0|1|2|3|4} [Options]
 *    - 0 - Default
 *    - 1 - Allow Dark Mode
 *    - 2 - Force Dark Mode
 *    - 3 - Force Light Mode
 *    - 4 - Max
 */
LightDarkColorMode(colorMode := 1) {
   if !Settings.DarkModeCompatible
      return

    try {
        static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
        static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
        static FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
        DllCall(SetPreferredAppMode, "int", colorMode)
        DllCall(FlushMenuThemes)
    }
}
