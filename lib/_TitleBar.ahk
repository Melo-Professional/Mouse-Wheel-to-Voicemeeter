/************************************************************************
 * @description Custom Title Bar (Isolated Window Messages)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/27
 * @version 1.5.2 (Windows 10 compatibility and title background)
 ***********************************************************************/

/* HOW TO USE
#Include .\_TitleBar.ahk

; Create your GUI layout normally
MainGui := Gui("-Caption")
MainGui.BackColor := "000000"
; Attach the custom emulated title bar layout

CustomTitleBar.Attach(MainGui, {
    Title: "Volume Mixer",
    ShowIcon: true,
    Min: true,
    Max: true, ; Turn off maximize if you don't need it
    Close: true
})
DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
; Add your standard window controls below the title bar region
MainGui.Add("Text", "X20 Y50 cWhite", "Your custom volume elements go here...")
MainGui.Show("W400 H300")
FrostedTheme.Apply(MainGui)
*/


class CustomTitleBar {
    static TitleBars := Map()
    static RegisteredMouseMonitor := false

    /**
     * Attaches a custom emulated title bar layout to an existing GUI.
     * @param {Gui} guiObj The target GUI object.
     * @param {Object} options Configuration object.
     * @param {String} options.Title Optional text string to show.
     * @param {Boolean} options.ShowIcon True to display the script/app icon on the left.
     * @param {Boolean} options.Min True to show Minimize button.
     * @param {Boolean} options.Max True to show Maximize/Restore button.
     * @param {Boolean} options.Close True to show Close button.
     * @param {Number} options.Height Title bar height in pixels (Default: 32).
     */
    static Attach(guiObj, options := "") {
        cfg := { Title: "", ShowIcon: true, Min: true, Max: true, Close: true, Height: 32 }
        if IsObject(options) {
            for k, v in options.OwnProps()
                cfg.%k% := v
        }

        tb := {
            Gui: guiObj,
            Hwnd: guiObj.Hwnd,
            Height: cfg.Height,
            Buttons: Map(),
            Cfg: cfg
        }
        
        this.TitleBars[guiObj.Hwnd] := tb

        guiObj.MarginX := 10
        guiObj.MarginY := 10

        ; 1. Draw Icon if enabled
        currentX := 16
        if (cfg.ShowIcon) {
            iconOpts := "X" currentX " Y" (cfg.Height-16)/2 " W16 H16"
            try {
                iconTarget := HasProp(App, "Icon") ? App.Icon : "shell32.dll"
                iconFlags := (A_IsCompiled && iconTarget == A_ScriptFullPath) ? "Icon1 W16 H16" : "W16 H16"
                
                localType := 0
                hIcon := LoadPicture(iconTarget, iconFlags, &localType)
                
                if (hIcon)
                    tb.IconCtrl := guiObj.Add("Pic", iconOpts, "HICON:*" hIcon)
                else
                    cfg.ShowIcon := false
            } catch {
                cfg.ShowIcon := false 
            }
            if (cfg.ShowIcon)
                currentX += 32
        }

        ; 2. Draw Optional Title Text
        if (cfg.Title != "") {
            guiObj.SetFont("S10 cWhite", "Segoe UI")
            w := guiObj.HasProp("Width") ? guiObj.Width : 400
            btnAreaWidth := (cfg.Close?46:0) + (cfg.Max?46:0) + (cfg.Min?46:0)
            textWidth := w - currentX - btnAreaWidth - 10
            
;            tb.TextCtrl := guiObj.Add("Text", "X" currentX " Y0 W" textWidth " H" cfg.Height " +0x200 BackgroundTrans", cfg.Title)
            tb.TextCtrl := guiObj.Add("Text", "X" currentX " Y0 W" textWidth " H" cfg.Height " +0x200", cfg.Title)
        }

        ; 3. Isolated Drag Support
        if (this.TitleBars.Count = 1) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0201, this.WM_LBUTTONDOWN.Bind(this)) ; Safe Click-to-drag
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this)) ; Safe Click-to-drag
            }
        }

        ; 4. Isolated Button Hover Monitor (No messy coordinates!)
        if (!this.RegisteredMouseMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0200, this.HandleMouseMove.Bind(this))  ; Track hover onset
                MessageManager.Register(0x02A3, this.HandleMouseLeave.Bind(this)) ; Track hover exit
            } else {
                OnMessage(0x0200, this.HandleMouseMove.Bind(this))  ; Track hover onset
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this)) ; Track hover exit
                this.RegisteredMouseMonitor := true
            }
        }

        guiObj.OnEvent("Size", this.OnGuiSize.Bind(this))
        guiObj.OnEvent("Close", (go) => this.CleanClose(go))
        guiObj.OnEvent("Escape", (go) => this.CleanClose(go))

        this.RenderButtons(tb)
        SetTimer(this.Prune.Bind(this), 1000)
        return tb
    }

    static Prune() {
        for parentHwnd, tb in this.TitleBars {
            if (!DllCall("user32\IsWindow", "Ptr", parentHwnd))
                this.TitleBars.Delete(parentHwnd)
        }

        ; If no GUIs remain, unhook mouse monitors and stop the timer
        if (this.TitleBars.Count == 0 && this.RegisteredMouseMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0201, this.WM_LBUTTONDOWN.Bind(this))
                MessageManager.Unregister(0x0200, this.HandleMouseMove.Bind(this))
                MessageManager.Unregister(0x02A3, this.HandleMouseLeave.Bind(this))
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this), 0)
                OnMessage(0x0200, this.HandleMouseMove.Bind(this), 0)
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this), 0)
            }
            this.RegisteredMouseMonitor := false
            SetTimer(this.Prune.Bind(this), 0) ; Turn off timer
        }
    }
    

/*     static CleanClose(go) {
        this.TitleBars.Delete(go.Hwnd)
        if IsSet(MessageManager) {
            MessageManager.Unregister(0x0201, this.WM_LBUTTONDOWN.Bind(this)) ; Safe Click-to-drag
            MessageManager.Unregister(0x0200, this.HandleMouseMove.Bind(this))  ; Track hover onset
            MessageManager.Unregister(0x02A3, this.HandleMouseLeave.Bind(this)) ; Track hover exit
        } else {
            OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this), 0)
            OnMessage(0x0200, this.HandleMouseMove.Bind(this), 0)
            OnMessage(0x02A3, this.HandleMouseLeave.Bind(this), 0)
        }
    }
 */

    static CleanClose(go) {
        if this.TitleBars.Has(go.Hwnd)
            this.TitleBars.Delete(go.Hwnd)
        
        ; Only unhook global mouse monitors when ALL custom title bars are closed
        if (this.TitleBars.Count == 0) {
            if IsSet(MessageManager) {
                MessageManager.Unregister(0x0201, this.WM_LBUTTONDOWN.Bind(this))
                MessageManager.Unregister(0x0200, this.HandleMouseMove.Bind(this))
                MessageManager.Unregister(0x02A3, this.HandleMouseLeave.Bind(this))
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this), 0)
                OnMessage(0x0200, this.HandleMouseMove.Bind(this), 0)
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this), 0)
            }
            this.RegisteredMouseMonitor := false
        }
    }

    static RenderButtons(tb) {
		cfg := tb.Cfg
		guiObj := tb.Gui
		bckcolor := tb.Gui.BackColor
		
		; Windows 11 (build 22000+) uses "Segoe Fluent Icons", Windows 10 uses "Segoe MDL2 Assets"
		iconFont := (VerCompare(A_OSVersion, "10.0.22000") >= 0) ? "Segoe Fluent Icons" : "Segoe MDL2 Assets"
		guiObj.SetFont("S8 cWhite", iconFont)
		
		btnWidth := 46
		btnHeight := tb.Height
		w := guiObj.HasProp("Width") ? guiObj.Width : 200
		
		if (cfg.Close) {
			btnX := "X" . (w - btnWidth)
			tb.Buttons["Close"] := guiObj.Add("Text", btnX . " Y0 W" btnWidth " H" btnHeight " +Center +0x200 +0x100 +Background" bckcolor, Chr(0xE8BB))
			tb.Buttons["Close"].OnEvent("Click", (*) => PostMessage(0x0010, 0, 0, guiObj.Hwnd))
		}
		if (cfg.Max) {
			offset := cfg.Close ? 2 : 1
			btnX := "X" . (w - (btnWidth * offset))
			tb.Buttons["Max"] := guiObj.Add("Text", btnX . " Y0 W" btnWidth " H" btnHeight " +Center +0x200 +0x100 +Background" bckcolor, Chr(0xE922))
			tb.Buttons["Max"].OnEvent("Click", (*) => WinGetMinMax(guiObj.Hwnd) ? guiObj.Restore() : guiObj.Maximize())
		}
		if (cfg.Min) {
			offset := (cfg.Close ? 1 : 0) + (cfg.Max ? 1 : 0) + 1
			btnX := "X" . (w - (btnWidth * offset))
			tb.Buttons["Min"] := guiObj.Add("Text", btnX . " Y0 W" btnWidth " H" btnHeight " +Center +0x200 +0x100 +Background" bckcolor, Chr(0xE921))
			tb.Buttons["Min"].OnEvent("Click", (*) => guiObj.Minimize())
		}

		guiObj.SetFont("S10 cWhite", "Segoe UI")
	}

    static OnGuiSize(guiObj, minMax, width, height) {
        if !this.TitleBars.Has(guiObj.Hwnd)
            return
        tb := this.TitleBars[guiObj.Hwnd]

        btnWidth := 46
        offset := 1
        
        if tb.Buttons.Has("Close") {
            tb.Buttons["Close"].Move(width - (btnWidth * offset))
            offset++
        }
        if tb.Buttons.Has("Max") {
            tb.Buttons["Max"].Move(width - (btnWidth * offset))
            tb.Buttons["Max"].Text := minMax == 1 ? Chr(0xE923) : Chr(0xE922)
            offset++
        }
        if tb.Buttons.Has("Min") {
            tb.Buttons["Min"].Move(width - (btnWidth * offset))
        }
    }

    static WM_LBUTTONDOWN(wp, lp, msg, hwnd) {
        if !this.TitleBars.Has(hwnd)
            return
        tb := this.TitleBars[hwnd]
        mouseY := lp >> 16
        
        if (mouseY <= tb.Height) {
            MouseGetPos ,,, &ctrlHwnd, 2
            for name, ctrl in tb.Buttons {
                ; Safety check for active window controls
                if (DllCall("user32\IsWindow", "Ptr", ctrl.Hwnd) && ctrl.Hwnd == ctrlHwnd)
                    return
            }
            PostMessage(0x00A1, 2,,, "ahk_id " hwnd)
        }
    }

    static HandleMouseMove(wParam, lParam, msg, hwnd) {
        for parentHwnd, tb in this.TitleBars {
            ; --- FIXED HERE: If the main window handle died, skip and clean it out ---
            if (!DllCall("user32\IsWindow", "Ptr", parentHwnd)) {
                this.TitleBars.Delete(parentHwnd)
                continue
            }
            
            for name, ctrl in tb.Buttons {
                if (ctrl.Hwnd == hwnd) {
                    tme := Buffer(8 + A_PtrSize * 2, 0)
                    NumPut("UInt", tme.Size, tme, 0)
                    NumPut("UInt", 2, tme, 4) 
                    NumPut("Ptr", hwnd, tme, 8)
                    DllCall("user32\TrackMouseEvent", "Ptr", tme)

                    if (name == "Close")
                        ctrl.Opt("+BackgroundE81123")
                    else
                        ctrl.Opt("+Background333333")
                    
                    ctrl.Redraw()
                    return 0
                }
            }
        }
    }

    static HandleMouseLeave(wParam, lParam, msg, hwnd) {
        for parentHwnd, tb in this.TitleBars {
            if (!DllCall("user32\IsWindow", "Ptr", parentHwnd))
                continue
                
            for name, ctrl in tb.Buttons {
                if (ctrl.Hwnd == hwnd) {
                    ;ctrl.Opt("+Background000000")
                    bc := tb.Gui.BackColor
                    ctrl.Opt("+Background" bc)
                    ctrl.Redraw()
                    return 0
                }
            }
        }
    }
}