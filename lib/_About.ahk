/************************************************************************
 * @description About GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/20
 * @version 1.7.7 (Icon distance)
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowAboutGUI() {
    MyGuiTitle := "About"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    offset := 5

    if IsFunctionDefined("CustomTitleBar") {
        MyGui.Opt("-Caption")
        titlebar := %"CustomTitleBar"%.Attach(MyGui, {
            Title: "",
            ShowIcon: false,
            Min: false,
            Max: false,
            Close: false
        })
        offset := 40
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    }

    UseAcrylicGUI := false
    if IsFunctionDefined("FrostedTheme") {
        UseAcrylicGUI := true
        offset := 30
    }

    TextNormalColor := "CCCCCC"
    TextHoverColor  := "FFFFFF"
    BGroundNormalColor  := "1b1b1b"
    BGroundHoverColor  := "313131"
    isHovering := false

    ; Define layout constants
    GuiWidth            := 460
    BtnWidth            := 80
    MyGui.MarginX       := 40
    MyGui.MarginY       := 30

    ; 1. Icon
    try {
        MyGui.Add("Picture", "xm y" offset " w64 h-1", App.Icon)
    } catch {
        MyGui.SetFont("s22 w500")
        MyGui.Add("Text", "xm y" offset " w64 h64", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeExtraBig " w700")
    if App.Name = App.NameCutted
        MyGui.Add("Text", "vTitle x+15 yp+10 vStrong_Title", App.Name)
    else
        MyGui.Add("Text", "vTitle x+15 yp vStrong_Title", App.NameCutted)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)

    ; 3. Description
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w400")
    MyGui.Add("Text", "xm y+50 w" . (GuiWidth - (MyGui.MarginX *2)), App.Description)

    if App.Github {
        GitNormalColor := "5865F2"
        GitHoverColor  := "5896f2"

        MyGui.SetFont("s" Settings.GuiFontSizeBig " c" GitNormalColor " w800")
        MyLink := MyGui.Add("Text", "-Tabstop xm y+20", "Check Github repository...")
        MyLink.OnEvent("Click", OpenGithub)
        MyLink.BypassTheme := true

        OpenGithub(*) {
            Run(App.Github)
            CleanDestroy()
        }
    }

    ; 4. Credits / Copyright
    MyGui.SetFont("cDefault s" Settings.GuiFontSizeSmall " w400")
    Credits := MyGui.Add("Text", "xm y+20 vSmooth_Credits", App.Copyright)
    Credits.OnEvent("Click", OpenMailTo)

    ; Button OK
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right

    if UseAcrylicGUI {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium " CWhite w700", Settings.GuiFontName)
        btnSave := MyGui.Add("Text", "x" btnX " y+10 w" BtnWidth " h25 Center 0x0200 Background" BGroundNormalColor " +Border", "OK")
        btnSave.BypassTheme := true
    } else {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnSave := MyGui.AddButton("x" btnX " y+10 w" BtnWidth " h25 Default", "&OK")
    }

    btnSave.OnEvent("Click", CleanDestroy)
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    if UseAcrylicGUI {
        if IsFunctionDefined("ApplyThemeToGui")
            %"ApplyThemeToGui"%(MyGui, "Dark")
        if IsFunctionDefined("FrostedTheme")
            %"FrostedTheme"%.Apply(MyGui)
    } else {
        ApplyThemeToGui(MyGui)
        WatchedGUIs.Push(MyGui)
    }

    MyGui.Show()

    ; --- Enable GUI Dragging ---
;    OnMessage(0x0201, WM_LBUTTONDOWN)

        if IsSet(MessageManager) {
            MessageManager.Register(0x0201, WM_LBUTTONDOWN)
        } else {
            OnMessage(0x0201, WM_LBUTTONDOWN)
        }

    WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
        if (hwnd == MyGui.Hwnd) {
            PostMessage(0x00A1, 2, 0, MyGui.Hwnd)
        }
    }

;    if (App.Github || UseAcrylicGUI) {
        if IsSet(MessageManager) {
            MessageManager.Register(0x0200, OnMouseMoveMyGui)
        } else {
            OnMessage(0x0200, OnMouseMoveMyGui)
        }
;    }

    OpenMailTo(*) {
        Run("mailto:melo@meloprofessional.com")
        CleanDestroy()
    }

    OnMouseMoveMyGui(wParam, lParam, msg, hwnd) {
        try {
/*             if (!Credits || !btnSave || !MyLink)
                return
        } catch {
            ToolTip(A_TickCount " catch ")
            return
        }
 */        
        if (hwnd == Credits.Hwnd || hwnd == btnSave.Hwnd || hwnd == MyLink.Hwnd) {
            ctrl := GuiCtrlFromHwnd(hwnd)

            if (!isHovering) {
                isHovering := true
                
                TRACKMOUSEEVENT := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
                NumPut("UInt", TRACKMOUSEEVENT.Size, TRACKMOUSEEVENT, 0)
                NumPut("UInt", 2,                    TRACKMOUSEEVENT, 4)
                NumPut("Ptr",  ctrl.Hwnd,          TRACKMOUSEEVENT, A_PtrSize == 8 ? 8 : 8)
                DllCall("TrackMouseEvent", "Ptr", TRACKMOUSEEVENT)
                
                if IsSet(MessageManager) {
                    MessageManager.Register(0x02A3, OnMouseLeaveMyGui)
                } else {
                    OnMessage(0x02A3, OnMouseLeaveMyGui)
                }
            }

            if (ctrl == MyLink) {
                DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
                ctrl.SetFont("c" GitHoverColor)
            } else if (ctrl == Credits) {
                DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
            } else if UseAcrylicGUI {
                ctrl.SetFont("c" TextHoverColor)
                ctrl.Opt("+Background" BGroundHoverColor)
            }
        }
    }
    }

    OnMouseLeaveMyGui(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == btnSave.Hwnd || hwnd == MyLink.Hwnd || hwnd == Credits.Hwnd) {
                ctrl := GuiCtrlFromHwnd(hwnd)

                if (ctrl == MyLink) {
                    ctrl.SetFont("c" GitNormalColor)
                } else if (ctrl == Credits) {
                } else if UseAcrylicGUI {
                    ctrl.SetFont("c" TextNormalColor)
                    ctrl.Opt("+Background" BGroundNormalColor)
                }
                isHovering := false
            }
        }
    }

    CleanDestroy(*) {
        ; Unregister the drag message handler

        if IsSet(MessageManager) {
            MessageManager.Unregister(0x0200, OnMouseMoveMyGui)
            MessageManager.Unregister(0x02A3, OnMouseLeaveMyGui)
            MessageManager.Unregister(0x0201, WM_LBUTTONDOWN)
        } else {
            OnMessage(0x0200, OnMouseMoveMyGui, 0)
            OnMessage(0x02A3, OnMouseLeaveMyGui, 0)
            OnMessage(0x0201, WM_LBUTTONDOWN, 0)
        }
        
        if IsFunctionDefined("RemoveGuiFromArray")
            %"RemoveGuiFromArray"%(MyGui)
        MyGui.Destroy()
    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}