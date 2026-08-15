/************************************************************************
 * @description Custom Title Bar (Isolated Window Messages & Native Move Loop)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/27
 * @version 1.6.0 (High-Hz smooth native dragging via MoveWindow)
 ***********************************************************************/

class CustomTitleBar {
    static TitleBars := Map()
    static RegisteredMouseMonitor := false

    /**
     * Attaches a custom emulated title bar layout to an existing GUI.
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
            
            tb.TextCtrl := guiObj.Add("Text", "X" currentX " Y0 W" textWidth " H" cfg.Height " +0x200", cfg.Title)
        }

        ; 3. Isolated Drag Support
        if (this.TitleBars.Count = 1) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0201, this.WM_LBUTTONDOWN.Bind(this))
            } else {
                OnMessage(0x0201, this.WM_LBUTTONDOWN.Bind(this))
            }
        }

        ; 4. Isolated Button Hover Monitor
        if (!this.RegisteredMouseMonitor) {
            if IsSet(MessageManager) {
                MessageManager.Register(0x0200, this.HandleMouseMove.Bind(this))
                MessageManager.Register(0x02A3, this.HandleMouseLeave.Bind(this))
            } else {
                OnMessage(0x0200, this.HandleMouseMove.Bind(this))
                OnMessage(0x02A3, this.HandleMouseLeave.Bind(this))
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
            SetTimer(this.Prune.Bind(this), 0)
        }
    }

    static CleanClose(go) {
        if this.TitleBars.Has(go.Hwnd)
            this.TitleBars.Delete(go.Hwnd)
        
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

    /**
     * Smooth high-Hz drag loop using direct MoveWindow Win32 API calls.
     * Supports high refresh rates (Sleep -1) and Win11-style maximized drag-to-restore.
     */
    static WM_LBUTTONDOWN(wp, lp, msg, hwnd) {
        if !this.TitleBars.Has(hwnd)
            return
        tb := this.TitleBars[hwnd]
        mouseY := lp >> 16
        
        if (mouseY <= tb.Height) {
            MouseGetPos ,,, &ctrlHwnd, 2
            for name, ctrl in tb.Buttons {
                if (DllCall("user32\IsWindow", "Ptr", ctrl.Hwnd) && ctrl.Hwnd == ctrlHwnd)
                    return
            }

            CoordMode "Mouse", "Screen"
            MouseGetPos &startX, &startY
            
            isMaximized := WinGetMinMax(hwnd) == 1
            
            ; --- 1. HANDLE MAXIMIZED WINDOW DRAGGING ---
            if (isMaximized) {
                ; Get current screen width of the maximized window to calculate click ratio
                WinGetPos &maxWinX, &maxWinY, &maxWinW, &maxWinH, "ahk_id " hwnd
                clickRatioX := (startX - maxWinX) / maxWinW

                ; Wait for the user to drag past a 5px threshold before un-maximizing
                while GetKeyState("LButton", "P") {
                    MouseGetPos &curX, &curY
                    if (Abs(curX - startX) > 5 || Abs(curY - startY) > 5) {
                        tb.Gui.Restore() ; Restore window dimensions
                        break
                    }
                    Sleep(-1)
                }

                ; If user released LButton before dragging past threshold, exit
                if !GetKeyState("LButton", "P")
                    return
                
                ; Calculate offset for the restored window size based on original click ratio
                WinGetPos &winX, &winY, &winW, &winH, "ahk_id " hwnd
                offsetX := winW * clickRatioX
                offsetY := startY - winY
            } 
            ; --- 2. HANDLE NORMAL WINDOW DRAGGING ---
            else {
                WinGetPos &winX, &winY, &winW, &winH, "ahk_id " hwnd
                offsetX := startX - winX
                offsetY := startY - winY
            }

            ; Lock mouse capture to window frame to prevent frame drops when dragging fast
            DllCall("user32\SetCapture", "Ptr", hwnd)

            ; --- 3. HIGH-REFRESH RATE NATIVE MOVE LOOP ---
            while GetKeyState("LButton", "P") {
                MouseGetPos &curX, &curY
                newX := curX - offsetX
                newY := curY - offsetY
                
                ; Fast Win32 Native API Move
                DllCall("user32\MoveWindow", "Ptr", hwnd, "Int", newX, "Int", newY, "Int", winW, "Int", winH, "Int", 1)
                
                ; -1 uncaps the loop, yielding control to system messages instantly for high-Hz displays
                Sleep(-1) 
            }

            DllCall("user32\ReleaseCapture")
            return 0
        }
    }

    static HandleMouseMove(wParam, lParam, msg, hwnd) {
        for parentHwnd, tb in this.TitleBars {
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
                    bc := tb.Gui.BackColor
                    ctrl.Opt("+Background" bc)
                    ctrl.Redraw()
                    return 0
                }
            }
        }
    }
}