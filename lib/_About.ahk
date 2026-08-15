/************************************************************************
 * @description About GUI (Cleaned up with GuiTracker & Native Move)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/14
 * @version 1.8.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowAboutGUI() {
    MyGuiTitle := "About"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    offset := 5

    if IsFunctionDefined("CustomTitleBar") {
        MyGui.Opt("-Caption")
        %"CustomTitleBar"%.Attach(MyGui, {
            Title: "",
            ShowIcon: false,
            Min: false,
            Max: false,
            Close: false
        })
        offset := 40
    }

    UseAcrylicGUI := IsFunctionDefined("FrostedTheme")
    if UseAcrylicGUI
        offset := 30

    ; Color Constants
	TextNormalColor				:= Settings.Theme.%CurrentActualTheme%.TextSmooth
	TextHoverColor				:= Settings.Theme.%CurrentActualTheme%.TextDefault
	BGroundNormalColor			:= Settings.Theme.%CurrentActualTheme%.Bg
	BGroundHoverColor			:= Settings.Theme.%CurrentActualTheme%.BgHover
	GitNormalColor				:= "5865F2"
	GitHoverColor				:= "5896f2"

	if UseAcrylicGUI {
		TextNormalColor			:= "CCCCCC"
		TextHoverColor			:= "FFFFFF"
		BGroundNormalColor		:= "1b1b1b"
		BGroundHoverColor		:= "313131"
		GitNormalColor			:= "5865F2"
		GitHoverColor			:= "5896f2"
	}

    ; Layout
    GuiWidth      := 460
    BtnWidth      := 80
    MyGui.MarginX := 40
    MyGui.MarginY := 30

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
    MyGui.Add("Text", "xm y+50 w" . (GuiWidth - (MyGui.MarginX * 2)), App.Description)

    ; 4. GitHub Link (Always gets hover effect)
    if App.Github {
        MyGui.SetFont("s" Settings.GuiFontSizeBig " c" GitNormalColor " w800")
        MyLink := MyGui.Add("Text", "-Tabstop xm y+20", "Check Github repository...")
        MyLink.OnEvent("Click", (*) => (Run(App.Github), CleanDestroy()))
        MyLink.BypassTheme := true
    }

    ; 5. Copyright / MailTo Link (Always gets hover effect)
    MyGui.SetFont("c" TextNormalColor " s" Settings.GuiFontSizeSmall " w400")
    Credits := MyGui.Add("Text", "xm y+20 vSmooth_Credits", App.Copyright)
    Credits.OnEvent("Click", (*) => (Run("mailto:melo@meloprofessional.com"), CleanDestroy()))

    ; 6. OK Button
;	btnX := MyGui.MarginX ; left
;	btnX := (GuiWidth - BtnWidth) // 2 ; center
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

	if IsSet(GuiTracker) {
		tracker := GuiTracker()
		tracker.AddGui := MyGui

		tracker.RegisterControl(btnSave, Map(
			"OnEnter", (ctrl) => (ctrl.SetFont("c" TextHoverColor), ctrl.Opt("+Background" BGroundHoverColor)),
			"OnLeave", (ctrl) => (ctrl.SetFont("c" TextNormalColor), ctrl.Opt("+Background" BGroundNormalColor))
		))

		tracker.RegisterControl(Credits, Map(
			"OnEnter", (ctrl) => ctrl.SetFont("c" TextHoverColor),
			;"OnLeave", (ctrl) => ctrl.SetFont("cDefault")
			"OnLeave", (ctrl) => ctrl.SetFont("c" TextNormalColor)
		))

		tracker.RegisterControl(MyLink, Map(
			"OnEnter", (ctrl) => ctrl.SetFont("c" GitHoverColor),
			"OnLeave", (ctrl) => ctrl.SetFont("c" GitNormalColor)
		))
	}

    ; Apply Themes
    if UseAcrylicGUI {
        if IsFunctionDefined("ApplyThemeToGui")
            %"ApplyThemeToGui"%(MyGui, "Dark")
        if IsFunctionDefined("FrostedTheme")
            %"FrostedTheme"%.Apply(MyGui)
    } else {
        if IsFunctionDefined("ApplyThemeToGui") {
            %"ApplyThemeToGui"%(MyGui)
            %"WatchedGUIs"%.Push(MyGui)
        }
    }

    MyGui.Show()

    if IsSet(MessageManager) {
        MessageManager.Register(0x0201, WM_LBUTTONDOWN)
    } else {
        OnMessage(0x0201, WM_LBUTTONDOWN)
    }

    WM_LBUTTONDOWN(wp, lp, msg, hwnd) {
        if (hwnd == MyGui.Hwnd) {
            ; Skip drag if user clicked directly on a control
            MouseGetPos ,,, &ctrlHwnd, 2
            if (ctrlHwnd && ctrlHwnd != MyGui.Hwnd)
                return

            CoordMode "Mouse", "Screen"
            MouseGetPos &startX, &startY
            WinGetPos &winX, &winY, &winW, &winH, "ahk_id " hwnd

            offsetX := startX - winX
            offsetY := startY - winY

            DllCall("user32\SetCapture", "Ptr", hwnd)

            while GetKeyState("LButton", "P") {
                MouseGetPos &curX, &curY
                DllCall("user32\MoveWindow", "Ptr", hwnd, "Int", curX - offsetX, "Int", curY - offsetY, "Int", winW, "Int", winH, "Int", 1)
                Sleep(-1)
            }

            DllCall("user32\ReleaseCapture")
            return 0
        }
    }

    CleanDestroy(*) {
        if IsSet(MessageManager) {
            MessageManager.Unregister(0x0201, WM_LBUTTONDOWN)
        } else {
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