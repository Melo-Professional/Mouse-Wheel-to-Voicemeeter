/************************************************************************
 * @description Theme Library to apply light / dark / auto modes 
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/14
 * @version 1.2.0
 ***********************************************************************/

#Requires AutoHotkey v2.0
;#Warn Unreachable, Off

global WatchedGUIs := []
global CurrentActualTheme := ""

ApplyTheme()

; --- New GUIs Logic's ---
CreateMyGui() {
    MyGuiTitle := "About"
    MyGuiOptions := "+LastFound -SysMenu"


    ; Check DarkMode
    if (IsSet(CurrentActualTheme) && CurrentActualTheme == "Dark") {
        MyGui := DarkGui(MyGuiOptions, MyGuiTitle)
    } else {
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
    }

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
;   global CurrentActualTheme

   colors := Settings.Theme.%CurrentActualTheme%
   isDark := (CurrentActualTheme == "Dark")

   guiObj.BackColor := colors.Bg

   ; 1.Title bar
   try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.Hwnd, "int", 20, "int*", isDark, "int", 4)

   ; 2. Find all controls
   for hwnd, ctrlObj in guiObj {
      try {

         ; Find types
         if (ctrlObj.Type == "Text" || ctrlObj.Type == "Checkbox") {
               ; names
               if (InStr(ctrlObj.Name, "Title") || (InStr(ctrlObj.Name, "Strong"))) {
                  ctrlObj.Opt("c" . colors.TextStrong)
               } else if (InStr(ctrlObj.Name, "Footer") || (InStr(ctrlObj.Name, "Smooth"))) {
                  ctrlObj.Opt("c" . colors.TextSmooth)
               } else {
                  ctrlObj.Opt("c" . colors.TextDefault)
               }
         }
         
         ; Edits or ListBoxes
         if (ctrlObj.Type == "Edit" || ctrlObj.Type == "ListBox") {
               ctrlObj.Opt("Background" . colors.Bg . " c" . colors.TextDefault)
         }

;         ctrlObj.Opt("Background" . colors.Bg )

               if (CurrentActualTheme == "Dark") {
                  DllCall("uxtheme.dll\SetWindowTheme", "ptr", ctrlObj.Hwnd, "str", "DarkMode_DarkTheme", "ptr", 0)
               } else {
                  DllCall("uxtheme.dll\SetWindowTheme", "ptr", ctrlObj.Hwnd, "str", "Explorer", "ptr", 0)
               }
               PostMessage(0x0128, 0x00010001, 0, ctrlObj.Hwnd)
         ; Button

/*          if (ctrlObj.Type == "Button") {
            try {
               if (CurrentActualTheme == "Dark") {
                  DllCall("uxtheme.dll\SetWindowTheme", "ptr", ctrlObj.Hwnd, "str", "DarkMode_DarkTheme", "ptr", 0)
               } else {
                  DllCall("uxtheme.dll\SetWindowTheme", "ptr", ctrlObj.Hwnd, "str", "Explorer", "ptr", 0)
               }
               PostMessage(0x0128, 0x00010001, 0, ctrlObj.Hwnd)
               continue
            }
         } */
         ctrlObj.Redraw()
      }
   }
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

    Settings.DesiredTheme := ThemeMode
    
    ; Sets current theme
    if (ThemeMode == "Auto") {
        OnMessage(0x1A, WindowsThemeChanged)
        CurrentActualTheme := GetWindowsTheme()
    } else {
        OnMessage(0x1A, WindowsThemeChanged, 0)
        CurrentActualTheme := ThemeMode
    }
    
    ; Menu Theme
;    modeInt := (CurrentActualTheme == "Dark") ? 2 : 1
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
            OSDThemeChange()
            ApplyTheme("Auto")
        }
    }
}

RefreshAllUIs() {
   global WatchedGUIs
    StartMenu()
    
    i := WatchedGUIs.Length
    while (i > 0) {
        guiObj := WatchedGUIs[i]
        
        try {
            if !WinExist(guiObj.Hwnd) {
                WatchedGUIs.RemoveAt(i)
            } else {
                ; Se existir, aplica o novo tema
                ApplyThemeToGui(guiObj)
            }
        } catch {
            WatchedGUIs.RemoveAt(i)
        }
        
        i--
    }
}

; --- Aux Funcs ---

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
    try {
        static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
        static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
        static FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
        DllCall(SetPreferredAppMode, "int", colorMode)
        DllCall(FlushMenuThemes)
    }
}

; Window Theme
Class DarkGui Extends Gui {
   Static Uxtheme                := DllCall("Kernel32.dll\GetModuleHandle", "Str", "Uxtheme.dll", "Ptr")
   Static AllowDarkModeForWindow := DllCall("Kernel32.dll\GetProcAddress", "Ptr", DarkGui.Uxtheme, "Ptr", 133, "Ptr")
   Static SetPreferredAppMode    := DllCall("Kernel32.dll\GetProcAddress", "Ptr", DarkGui.Uxtheme, "Ptr", 135, "Ptr")
   Static FlushMenuThemes        := DllCall("Kernel32.dll\GetProcAddress", "Ptr", DarkGui.Uxtheme, "Ptr", 136, "Ptr")
   ; DarkGui color scheme - might be altered before you create a new Gui object
   Static ColorWindow := "0x202020" ; window background color        - must be a string !!!
   Static ColorCtrl   := "0x313131" ; background color for controls  - must be a string !!!
   Static ColorFont   := "0xFFFFFF" ; font color                     - must be a string !!!
   ;--------------------------------------------------------------------------------------------------------------------
   OnCtlColorListbox := ObjBindMethod(This, "CtlColorListbox")
   ListViewSubclass  := ObjBindMethod(This, "HdrTxtColor")
   ;--------------------------------------------------------------------------------------------------------------------
   __New(Options?, Title?, EventObj?) {
      Static OSMinVer := "10.0.26100"
      If (VerCompare(A_OSVersion, OSMinVer) < 0)
         Throw Error("Class DarkGui requires at least OSVersion " OSMinVer "!", -1, "Current version: " A_OSVersion)
      Super.__New(Options?, Title?, EventObj?)
      ; DWMWA_USE_IMMERSIVE_DARK_MODE = 20
   	DllCall("Dwmapi.dll\DwmSetWindowAttribute", "Ptr", This.Hwnd, "Int", 20, "Int*", True, "Int", 4)
   	DllCall(DarkGui.SetPreferredAppMode, "Int", 2) ; ForceDark
      DllCall(DarkGui.AllowDarkModeForWindow, "Ptr", This.Hwnd, "UInt", 1)
   	DllCall(DarkGui.FlushMenuThemes)
      This.CtrlColor := DarkGui.ColorCtrl
      This.GuiColor  := DarkGui.ColorWindow
   	This.BackColor := This.GuiColor
      This.FontColor := DarkGui.ColorFont
      This.SetFont("c" This.FontColor)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddButton(Options?, Text?) {
      Local Ctrl := Super.AddButton(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.GuiColor)
      PostMessage(0x0128, 0x00010001, 0, Ctrl) ; WM_UPDATEUISTATE - UIS_SET - UISF_HIDEFOCUS
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddCheckBox(Options?, Text?) {
      Local Ctrl := Super.AddCheckBox(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddComboBox(Options?, Text?) {
      ES_NOHIDESEL           := 0x0100
      Local Ctrl := Super.AddComboBox(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.CtrlColor . " c" . This.FontColor)
      Local List := This.GetComboList(Ctrl)
      This.SetDarkTheme(List, "DarkMode_DarkTheme")
      OnMessage(0x0134, This.OnCtlColorListbox) ; WM_CTLCOLORLISTBOX
      SendMessage(0x0142, 0, 0xFFFF, Ctrl) ; CB_SETEDITSEL -> remove selection
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddDDL(Options?, Text?) {
      Local Ctrl := Super.AddDDL(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Local List := This.GetComboList(Ctrl)
      This.SetDarkTheme(List, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.CtrlColor . " c" . This.FontColor)
      PostMessage(0x0128, 0x00010001, 0, Ctrl) ; WM_UPDATEUISTATE - UIS_SET - UISF_HIDEFOCUS
      OnMessage(0x0134, This.OnCtlColorListbox) ; WM_CTLCOLORLISTBOX
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddEdit(Options?, Text?) {
      Local Ctrl := Super.AddEdit(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.CtrlColor . " c" . This.FontColor)
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddListBox(Options?, Text?) {
      Local Ctrl := Super.AddListBox(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.CtrlColor . " c" . This.FontColor)
      Ctrl.Opt("-E0x200 ") ; +Border
      PostMessage(0x0128, 0x00010001, 0, Ctrl) ; WM_UPDATEUISTATE - UIS_SET - UISF_HIDEFOCUS
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddListView(Options?, Text?) {
      Local Ctrl := Super.AddListView(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.CtrlColor . " c" . This.FontColor)
      Ctrl.Opt("-E0x200 ") ; +Border
      Local Hdr := SendMessage(0x101F, 0, 0, Ctrl) ; LVM_GETHEADER
      This.SetDarkTheme(Hdr, "DarkMode_DarkTheme") ; "DarkMode_ItemsView") ; "DarkMode_DarkTheme"
      PostMessage(0x0128, 0x00010001, 0, Ctrl) ; WM_UPDATEUISTATE - UIS_SET - UISF_HIDEFOCUS
      This.SetWindowSubclass(Ctrl, This.ListViewSubclass, This.FontColor)
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddProgress(Options?, Text?) {
      Local Ctrl := Super.AddProgress(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddRadio(Options?, Text?) {
      Local Ctrl := Super.AddRadio(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddStatusBar(Options?, Text?) {
      Local Ctrl := Super.AddStatusBar(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddText(Options?, Text?) {
      Local Ctrl := Super.AddText(Options?, Text?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Ctrl.Opt("+Background" . This.GuiColor . " c" . This.FontColor)
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddTreeView(Options?) {
      Local Ctrl := Super.AddTreeView(Options?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      ; Ctrl.Opt("+Background" . This.CtrlColor . " c" . This.FontColor)
      Ctrl.Opt("-0x0020") ; TVS_SHOWSELALWAYS
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   AddUpDown(Options?) {
      Local Ctrl := Super.AddUpDown(Options?)
      This.SetDarkTheme(Ctrl, "DarkMode_DarkTheme")
      Return Ctrl
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Get the HWND of the automatically created ListBox of the ComboBox/DDL control
   GetComboList(Ctrl) {
      Static WM_CTLCOLORLISTBOX := 0x0134
      Static CBISize := 40 + (A_PtrSize * 3)
      Local CBI := Buffer(CBISize, 0)
      NumPut("UInt", CBISize, CBI)
      DllCall("GetComboBoxInfo", "Ptr", Ctrl.Hwnd, "Ptr", CBI)
      Return NumGet(CBI, 40 + (A_PtrSize * 2), "UInt")
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Set the dark theme for controls
   SetDarkTheme(Hwnd, Mode, Classes?) {
      Hwnd := IsObject(Hwnd) && Hwnd.HasProp("Hwnd") ? Hwnd.Hwnd : Hwnd
      DllCall(DarkGui.AllowDarkModeForWindow, "Ptr", Hwnd, "UInt", 1)
      Local ClsPtr := IsSet(Classes) ? StrPtr(Classes) : 0
      DllCall("Uxtheme.dll\SetWindowTheme", "Ptr", Hwnd, "Str", Mode, "Ptr", ClsPtr)
      SendMessage(WM_THEMECHANGED := 0x031A, 0, 0, Hwnd)
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; SetWindowSubclass -> https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-setwindowsubclass
   ; SUBCLASSPROC      -> https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc
   ; The CallbackFunc must accept at least 6 parameters.
   ; -------------------------------------------------------------------------------------------------------------------
   SetWindowSubclass(HWND, CallbackFunc, Data := 0) {
      Static Subclassed := Map()
      HWND := IsObject(HWND) && HWND.HasProp("Hwnd") ? HWND.Hwnd : HWND
      Local CB := 0
      If Subclassed.Has(HWND) {
         CB := Subclassed[HWND]
         DllCall("RemoveWindowSubclass", "Ptr", HWND, "Ptr", CB, "Ptr", HWND)
         CallbackFree(CB)
         Subclassed.Delete(HWND)
         If (CallbackFunc = "")
            Return True
      }
      If CallbackFunc Is BoundFunc || (CallbackFunc Is Func && CallbackFunc.MinParams > 5) {
         CB := CallbackCreate(CallbackFunc, , 6)
         If DllCall("SetWindowSubclass", "Ptr", HWND, "Ptr", CB, "Ptr", HWND, "Ptr", Data) {
            Subclassed[HWND] := CB
            Return True
         }
         CallbackFree(CB)
      }
      Return False
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Set the colors for the listboxes automatically created for ComboBox/DDL controls
   CtlColorListbox(wParam, lParam, Msg, Hwnd) {
      Static DC_BRUSH := DllCall("GetStockObject", "Int", 18, "Ptr")
      Critical(-1)
      If !GuiCtrlFromHwnd(Hwnd) {
			DllCall("SetTextColor", "Ptr", wParam, "UInt", This.FontColor)
			DllCall("SetBkColor", "Ptr", wParam, "UInt", This.CtrlColor)
 			DllCall("SetDCBrushColor", "Ptr", wParam, "UInt", This.CtrlColor, "UInt")
         Return DC_BRUSH
      }
   }
   ; -------------------------------------------------------------------------------------------------------------------
   ; Set the text color for the built-in ListView Header control
   HdrTxtColor(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData) {
      Critical -1
      Switch uMsg {
         Case 0x004E: ; WM_NOTIFY - header notifications
            Local HCtrl := NumGet(LParam, "UInt")
            Local Code := NumGet(LParam, A_PtrSize * 2, "Int")                ; NM_CUSTOMDRAW
            If (Code = -12) && (WinGetClass(HCtrl) = "SysHeader32") {
               Switch NumGet(LParam, A_PtrSize * 3, "UInt") {                 ; dwDrawStage
                  Case 0x00010001:                                            ; CDDS_ITEMPREPAINT
                     Local HDC := NumGet(LParam, A_PtrSize * 4, "UPtr")
                     DllCall("SetTextColor", "Ptr", HDC, "UInt", dwRefData)
                     Return 0                                                 ; CDRF_DODEFAULT
                  Case 0x00000001:                                            ; CDDS_PREPAINT
                     Return 0x00000020                                        ; CDRF_NOTIFYITEMDRAW
                  Default:
                     Return 0                                                 ; CDRF_DODEFAULT
               }
            }
         Case 0x0002: ; WM_DESTROY
            This.SetWindowSubclass(hWnd, 0)
            OnMessage(0x0134, This.OnCtlColorListbox, 0) ; WM_CTLCOLORLISTBOX

      }
      Return DllCall("DefSubclassProc", "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lparam)
   }
}
; ======================================================================================================================


; ----------------------------------------------------------------------------------------------------------------------
; Gui example
/* 
G := DarkGui()
G.SetFont("s10")
G.MarginX := 10
G.MarginY := 10
G.AddButton("w200 Section", "Button")
G.AddEdit("w200 r3", "Multiline`nedit control!")
G.AddEdit("w200", "Singleline Edit")
G.AddUpDown()
G.AddListBox("w200 r3",["ListBox 1", "LB 2", "LB 3", "LB 4", "LB 5"])
G.AddRadio("xm", "Radio 1").Type
G.AddRadio("x+10 yp", "Radio 2")
G.AddRadio("x+10 yp", "Radio 3")
G.AddCheckBox("xm", "CheckBox 1")
LV := G.AddListView("ys w300 r3 Section", ["ListView"])
LV.Add("", "Value 1")
LV.Add("", "Value 2")
LV.Add("", "Value 3")
LV.Add("", "Value 4")
LV.ModifyCol(1, "AutoHdr")
G.AddText("xs wp", "Text control with`ntwo lines!")
G.AddDDL("xs wp r3 Choose1", ["DDL 1", "DDL 2", "DDL 3", "DDL 4"])
G.AddComboBox("xs y+15 wp r3 Choose1", ["Combo 1", "Combo 2", "Combo 3", "Combo 4"])
TV := G.AddTreeView("ys wp r6 Checked Section")
P1 := TV.Add("TreeView")
Loop 10
      TV.Add("Child #" A_Index, P1)
G.AddProgress("xs wp", 75)
G.AddStatusBar(, "Bar's starting text (omit to start off empty).")
G.Show()
 */
 
; ======================================================================================================================
