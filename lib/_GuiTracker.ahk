/************************************************************************
 * @description Creates reactions to GUI and it's objects for clicks and mouse wheel
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/13
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

class GuiTracker {
    static instances := Map()
    static hooksRegistered := false
    static boundDispatchLClick := 0
    static boundDispatchDblClick := 0
    static boundDispatchRClick := 0
    static boundOnMouseWheel := 0

    __New() {
        this.gui := 0
        this.hwnd := 0
        this.controls := Map()          ; ctrlHwnd -> {ctrl, events}
        this.guiEvents := Map()         ; Map of GUI-level events
        this.hoveredCtrlHwnd := 0
        
        ; Auto-dismiss configuration
        this.autoDismiss := false
        this.dismissAction := "Hide"    ; "Hide" or "Destroy"
        this.dismissTimeout := 1000     ; ms
        this.leaveStartTime := 0
        this.isMouseOverGui := false
    }

    ; Property setter: tracker.addgui := myGui
    AddGui {
        set {
            this.gui := value
            this.hwnd := value.Hwnd

            ; Register GUI instance mapping
            GuiTracker.instances[this.hwnd] := this

            ; Register global message hooks if this is the first active instance
            GuiTracker._RegisterHooks()

            ; Start polling loop (runs every 30ms)
            this.pollTimer := ObjBindMethod(this, "_Poll")
            SetTimer(this.pollTimer, 30)

            ; Clean up automatically when GUI closes
            this.gui.OnEvent("Close", ObjBindMethod(this, "Destroy"))
        }
        get => this.gui
    }

    ; Register callbacks directly for the GUI window itself
    RegisterGui(eventsMap) {
        this.guiEvents := eventsMap
    }

    ; Register callbacks for a control (or pass guiObj directly)
    RegisterControl(ctrlObj, eventsMap) {
        if (ctrlObj is Gui) {
            this.RegisterGui(eventsMap)
            return
        }

        ; Automatically enable click notifications for Static text/image controls (0x100 = SS_NOTIFY)
        if WinGetClass(ctrlObj.Hwnd) == "Static" {
            ctrlObj.Opt("+0x100")
        }

        this.controls[ctrlObj.Hwnd] := { ctrl: ctrlObj, events: eventsMap }
    }

    ; ==========================================================================
    ; AUTO-DISMISS CONFIGURATION (MOUSE LEAVE)
    ; ==========================================================================
    ; Use this method to automatically hide or destroy a GUI when the mouse leaves.
    ; 
    ; Parameters:
    ;   action    - "Hide"    : Calls myGui.Hide(). Preserves state/controls so it can be re-shown.
    ;               "Destroy" : Calls myGui.Destroy(). Completely dismantles the GUI window,
    ;                           frees OS resources, and unhooks timers/events.
    ;   timeoutMs - Time in milliseconds after mouse leaves before action fires (default 1000ms).
    ;
    ; Example Usage:
    ;   tracker.SetAutoDismiss("Hide", 2000)    ; Hides GUI after mouse leaves for 2 seconds
    ;   tracker.SetAutoDismiss("Destroy", 1000) ; Destroys GUI after mouse leaves for 1 second
    SetAutoDismiss(action := "Hide", timeoutMs := 1000) {
        this.autoDismiss := true
        this.dismissAction := action
        this.dismissTimeout := timeoutMs
    }

    ; --- Internal Polling Loop ---
    _Poll() {
        if !this.hwnd || !WinExist(this.hwnd)
            return

        MouseGetPos(&mouseX, &mouseY, &winHwnd, &ctrlHwnd, 2)

        ; 1. GUI Window Boundary & Enter/Leave Tracking
        if (winHwnd == this.hwnd) {
            if (!this.isMouseOverGui) {
                this.isMouseOverGui := true
                this.leaveStartTime := 0
                
                ; Trigger GUI-level OnEnter
                if this.guiEvents.Has("OnEnter") {
                    fn := this.guiEvents["OnEnter"]
                    guiObj := this.gui
                    SetTimer(() => fn(guiObj), -1)
                }
            }
        } else {
            if (this.isMouseOverGui) {
                this.isMouseOverGui := false
                this.leaveStartTime := A_TickCount
                
                ; Trigger GUI-level OnLeave
                if this.guiEvents.Has("OnLeave") {
                    fn := this.guiEvents["OnLeave"]
                    guiObj := this.gui
                    SetTimer(() => fn(guiObj), -1)
                }
            }

            ; ------------------------------------------------------------------
            ; Auto-Dismiss Execution on Mouse Leave
            ; ------------------------------------------------------------------
            if (this.autoDismiss && this.leaveStartTime > 0) {
                if (A_TickCount - this.leaveStartTime >= this.dismissTimeout) {
                    this._ExecuteDismiss()
                    return
                }
            }
        }

        ; 2. Control Hover & Leave Tracking
        if (ctrlHwnd != this.hoveredCtrlHwnd) {
            ; Trigger Leave on old control
            if (this.hoveredCtrlHwnd && this.controls.Has(this.hoveredCtrlHwnd)) {
                data := this.controls[this.hoveredCtrlHwnd]
                if data.events.Has("OnLeave")
                    data.events["OnLeave"](data.ctrl)
            }

            this.hoveredCtrlHwnd := ctrlHwnd

            ; Trigger Enter on new control
            if (this.controls.Has(ctrlHwnd)) {
                data := this.controls[ctrlHwnd]
                if data.events.Has("OnEnter")
                    data.events["OnEnter"](data.ctrl)
            }
        }
    }

    ; Executes the dismissal (Hide vs Destroy) based on SetAutoDismiss settings
    _ExecuteDismiss() {
        this.Cleanup()
        
        if (this.dismissAction = "Destroy") {
            ; Completely destroy window & free resources
            this.gui.Destroy()
        } else {
            ; Simply hide window (can be shown again with myGui.Show())
            this.gui.Hide()
        }
    }

    Destroy(guiObj := 0) {
        this.Cleanup()
    }

    ; --- Centralized Cleanup Method ---
    Cleanup() {
        if this.HasOwnProp("pollTimer")
            SetTimer(this.pollTimer, 0)
            
        if this.hwnd && GuiTracker.instances.Has(this.hwnd) {
            GuiTracker.instances.Delete(this.hwnd)
        }

        ; If no active GUI instances remain, unregister all OnMessage hooks
        if (GuiTracker.instances.Count == 0) {
            GuiTracker._UnregisterHooks()
        }
    }

    ; --- Windows Message Intercepts ---
    static _RegisterHooks() {
        if (GuiTracker.hooksRegistered)
            return
        
        GuiTracker.boundDispatchLClick   := (wParam, lParam, msg, hwnd) => GuiTracker._DispatchEvent("OnLClick", hwnd)
        GuiTracker.boundDispatchDblClick := (wParam, lParam, msg, hwnd) => GuiTracker._DispatchEvent("OnDblClick", hwnd)
        GuiTracker.boundDispatchRClick   := (wParam, lParam, msg, hwnd) => GuiTracker._DispatchEvent("OnRClick", hwnd)
        GuiTracker.boundOnMouseWheel     := ObjBindMethod(GuiTracker, "_OnMouseWheel")

		if IsSet(MessageManager) {
            MessageManager.Register(0x0201, GuiTracker.boundDispatchLClick)
            MessageManager.Register(0x0203, GuiTracker.boundDispatchDblClick)
            MessageManager.Register(0x0204, GuiTracker.boundDispatchRClick)
            MessageManager.Register(0x020A, GuiTracker.boundOnMouseWheel)
        } else {
			OnMessage(0x0201, GuiTracker.boundDispatchLClick)
			OnMessage(0x0203, GuiTracker.boundDispatchDblClick)
			OnMessage(0x0204, GuiTracker.boundDispatchRClick)
			OnMessage(0x020A, GuiTracker.boundOnMouseWheel)
        }


        GuiTracker.hooksRegistered := true
    }

    static _UnregisterHooks() {
        if (!GuiTracker.hooksRegistered)
            return

		if IsSet(MessageManager) {
            MessageManager.Unregister(0x0201, GuiTracker.boundDispatchLClick)
            MessageManager.Unregister(0x0203, GuiTracker.boundDispatchDblClick)
            MessageManager.Unregister(0x0204, GuiTracker.boundDispatchRClick)
            MessageManager.Unregister(0x020A, GuiTracker.boundOnMouseWheel)
        } else {
			OnMessage(0x0201, GuiTracker.boundDispatchLClick, 0)
			OnMessage(0x0203, GuiTracker.boundDispatchDblClick, 0)
			OnMessage(0x0204, GuiTracker.boundDispatchRClick, 0)
			OnMessage(0x020A, GuiTracker.boundOnMouseWheel, 0)
		}

        GuiTracker.boundDispatchLClick   := 0
        GuiTracker.boundDispatchDblClick := 0
        GuiTracker.boundDispatchRClick   := 0
        GuiTracker.boundOnMouseWheel     := 0

        GuiTracker.hooksRegistered := false
    }

    static _DispatchEvent(eventName, hwnd) {
        ; Traverse parent hierarchy to find which registered GuiTracker instance owns 'hwnd'
        currHwnd := hwnd
        targetTracker := 0

        while (currHwnd) {
            if GuiTracker.instances.Has(currHwnd) {
                targetTracker := GuiTracker.instances[currHwnd]
                break
            }
            ; Step up to immediate parent window (GA_PARENT = 1)
            currHwnd := DllCall("GetAncestor", "Ptr", currHwnd, "UInt", 1, "Ptr")
        }

        if (targetTracker) {
            ; 1. Check if the clicked target is a registered Control
            if targetTracker.controls.Has(hwnd) {
                data := targetTracker.controls[hwnd]
                if data.events.Has(eventName) {
                    try DllCall("SetFocus", "Ptr", targetTracker.hwnd)
                    fn := data.events[eventName]
                    ctrl := data.ctrl
                    SetTimer(() => fn(ctrl), -1)
                }
            ; 2. Fallback to GUI-level click event (clicked empty space on GUI/Child panel)
            } else if targetTracker.guiEvents.Has(eventName) {
                fn := targetTracker.guiEvents[eventName]
                guiObj := targetTracker.gui
                SetTimer(() => fn(guiObj), -1)
            }
        }
    }

    static _OnMouseWheel(wParam, lParam, msg, hwnd) {
        MouseGetPos(,, &winHwnd, &ctrlHwnd, 2)

        ; Traverse hierarchy to find matching instance
        currHwnd := ctrlHwnd ? ctrlHwnd : winHwnd
        targetTracker := 0

        while (currHwnd) {
            if GuiTracker.instances.Has(currHwnd) {
                targetTracker := GuiTracker.instances[currHwnd]
                break
            }
            currHwnd := DllCall("GetAncestor", "Ptr", currHwnd, "UInt", 1, "Ptr")
        }

        if (targetTracker) {
            eventsMap := 0
            targetObj := 0

            if targetTracker.controls.Has(ctrlHwnd) {
                eventsMap := targetTracker.controls[ctrlHwnd].events
                targetObj := targetTracker.controls[ctrlHwnd].ctrl
            } else if (targetTracker.guiEvents.Count > 0) {
                eventsMap := targetTracker.guiEvents
                targetObj := targetTracker.gui
            }

            if (eventsMap) {
                delta := (wParam >> 16) & 0xFFFF
                delta := (delta > 0x7FFF) ? delta - 0x10000 : delta
                
                if (delta > 0 && eventsMap.Has("OnWheelUp")) {
                    fn := eventsMap["OnWheelUp"]
                    SetTimer(() => fn(targetObj), -1)
                } else if (delta < 0 && eventsMap.Has("OnWheelDown")) {
                    fn := eventsMap["OnWheelDown"]
                    SetTimer(() => fn(targetObj), -1)
                }
            }
        }
    }
}


/*
#Requires AutoHotkey v2.0
#Include "lib/GuiTracker.ahk"

; ==============================================================================
; 1. PARENT GUI SETUP
; ==============================================================================
myGui := Gui("+AlwaysOnTop +Resize", "GuiTracker - Parent & Child Showcase")
myGui.SetFont("s9", "Segoe UI")

; --- Section 1: Basic Controls ---
myGui.Add("GroupBox", "x10 y10 w260 h150", "Interactive Buttons & Text")
boxHover := myGui.Add("Text", "x20 y35 w240 h40 Center +Border 0x200 BackgroundD3D3D3", "Hover / Click / Wheel Me")
btn1     := myGui.Add("Button", "x20 y85 w115 h30", "Action Button")
chk1     := myGui.Add("CheckBox", "x145 y85 w115 h30", "Enable Feature")

; --- Section 2: Selections & Inputs ---
myGui.Add("GroupBox", "x280 y10 w260 h150", "Inputs & Pickers")
editBox  := myGui.Add("Edit", "x290 y35 w240 h25", "Type something...")
ddl      := myGui.Add("DropDownList", "x290 y70 w240 Choose1", ["Option Alpha", "Option Beta", "Option Gamma"])
rad1     := myGui.Add("Radio", "x290 y110 w110 h25 Group Checked", "Mode A")
rad2     := myGui.Add("Radio", "x410 y110 w110 h25", "Mode B")

; --- Section 3: Data Views & Gauges ---
myGui.Add("GroupBox", "x10 y170 w260 h180", "Gauges & Controls")
slider1  := myGui.Add("Slider", "x20 y195 w240 h30 Range0-100 ToolTip", 40)
progBar  := myGui.Add("Progress", "x20 y235 w240 h20 c0x00AAFF", 40)
listView := myGui.Add("ListView", "x20 y265 w240 h75 +Grid", ["ID", "Name"])
listView.Add("", "1", "Alpha")
listView.Add("", "2", "Beta")

; Statusbar at bottom for live feedback
statusBar := myGui.Add("StatusBar",, "Hover over or interact with any window/control...")
LogEvent(msg) => statusBar.SetText(" " . msg)

; Show Parent GUI
myGui.Show("w550 h385")

; ==============================================================================
; 2. EMBEDDED CHILD GUI SETUP
; ==============================================================================
; Create a child window styled with a distinct background border
childGui := Gui("+Parent" . myGui.Hwnd . " -Caption +ToolWindow", "")
childGui.SetFont("s9", "Segoe UI")
childGui.BackColor := "EAEAEA"

childGui.Add("GroupBox", "x5 y5 w250 h170", "Embedded Child Panel Area")
childGui.Add("Text", "x15 y30 w230 h35 Center", "Click/Wheel empty panel area or controls below:")
childBtn := childGui.Add("Button", "x15 y70 w230 h30", "Child GUI Button")
childEdit:= childGui.Add("Edit", "x15 y110 w230 h25", "Child Edit Box...")

; Display Child GUI embedded inside the parent (Section 4 position)
childGui.Show("x280 y170 w260 h180")

; ==============================================================================
; 3. TRACKER 1: PARENT GUI & CONTROLS REGISTRATION
; ==============================================================================
parentTracker := GuiTracker()
parentTracker.AddGui := myGui


; Optional: Set GUI to destroy when mouse leaves for 1 seconds
;parentTracker.SetAutoDismiss("Destroy", 1000)
; Optional: Set GUI auto-hide when mouse leaves for 2.5 seconds
;parentTracker.SetAutoDismiss("Hide", 2500)

; A. Parent GUI Window Events (Fired when clicking/hovering empty space on parent)
parentTracker.RegisterGui(Map(
    "OnEnter",    (guiObj) => LogEvent("[Parent GUI] Mouse Entered Window"),
    "OnLeave",    (guiObj) => LogEvent("[Parent GUI] Mouse Left Window"),
    "OnLClick",   (guiObj) => LogEvent("[Parent GUI] Clicked Empty Background Area"),
    "OnRClick",   (guiObj) => LogEvent("[Parent GUI] Right-Clicked Empty Background Area"),
    "OnWheelUp",  (guiObj) => LogEvent("[Parent GUI] Scrolled Wheel UP on Background"),
    "OnWheelDown",(guiObj) => LogEvent("[Parent GUI] Scrolled Wheel DOWN on Background")
))

; B. Interactive Hover Text Box
parentTracker.RegisterControl(boxHover, Map(
    "OnEnter",    (ctrl) => (ctrl.Opt("+Background00AAFF"), ctrl.Redraw(), LogEvent("Entered Hover Box")),
    "OnLeave",    (ctrl) => (ctrl.Opt("+BackgroundD3D3D3"), ctrl.Redraw(), LogEvent("Left Hover Box")),
    "OnLClick",   (ctrl) => (SoundBeep(800, 80), LogEvent("Left Clicked Hover Box")),
    "OnRClick",   (ctrl) => LogEvent("Right Clicked Hover Box"),
    "OnDblClick", (ctrl) => LogEvent("Double Clicked Hover Box"),
    "OnWheelUp",  (ctrl) => LogEvent("Wheel UP on Hover Box"),
    "OnWheelDown",(ctrl) => LogEvent("Wheel DOWN on Hover Box")
))

; C. Standard Controls
parentTracker.RegisterControl(btn1, Map(
    "OnEnter",  (ctrl) => LogEvent("Hovering Action Button"),
    "OnLeave",  (ctrl) => LogEvent("Left Action Button"),
    "OnLClick", (ctrl) => MsgBox("Parent Action Button Clicked!", "GuiTracker")
))

parentTracker.RegisterControl(chk1, Map(
    "OnLClick", (ctrl) => LogEvent("Checkbox toggled: Value = " . ctrl.Value)
))

parentTracker.RegisterControl(editBox, Map(
    "OnEnter",  (ctrl) => LogEvent("Focused/Hovered Parent Edit Box")
))

parentTracker.RegisterControl(ddl, Map(
    "OnEnter",    (ctrl) => LogEvent("Hovering DropDownList"),
    "OnWheelUp",  (ctrl) => LogEvent("Scrolled Up on DropDownList"),
    "OnWheelDown",(ctrl) => LogEvent("Scrolled Down on DropDownList")
))

parentTracker.RegisterControl(rad1, Map("OnEnter", (ctrl) => LogEvent("Hovering Radio Mode A")))
parentTracker.RegisterControl(rad2, Map("OnEnter", (ctrl) => LogEvent("Hovering Radio Mode B")))

parentTracker.RegisterControl(slider1, Map(
    "OnEnter", (ctrl) => LogEvent("Hovering Slider"),
    "OnWheelUp", (ctrl) => (
        ctrl.Value := Min(100, ctrl.Value + 5),
        progBar.Value := ctrl.Value,
        LogEvent("Slider Adjusted: " . ctrl.Value)
    ),
    "OnWheelDown", (ctrl) => (
        ctrl.Value := Max(0, ctrl.Value - 5),
        progBar.Value := ctrl.Value,
        LogEvent("Slider Adjusted: " . ctrl.Value)
    )
))

parentTracker.RegisterControl(listView, Map(
    "OnEnter",    (ctrl) => LogEvent("Hovering ListView Grid"),
    "OnLClick",   (ctrl) => LogEvent("Clicked ListView (Row " . ctrl.GetNext() . ")")
))

; ==============================================================================
; 4. TRACKER 2: CHILD GUI & CONTROLS REGISTRATION (OPTION A)
; ==============================================================================
childTracker := GuiTracker()
childTracker.AddGui := childGui

; A. Child GUI Window Events (Fired when interacting with child panel background)
childTracker.RegisterGui(Map(
    "OnEnter",    (guiObj) => LogEvent("[Child Panel] Mouse Entered Panel Area"),
    "OnLeave",    (guiObj) => LogEvent("[Child Panel] Mouse Left Panel Area"),
    "OnLClick",   (guiObj) => LogEvent("[Child Panel] Clicked Background of Panel"),
    "OnRClick",   (guiObj) => LogEvent("[Child Panel] Right-Clicked Background of Panel"),
    "OnWheelUp",  (guiObj) => LogEvent("[Child Panel] Scrolled UP on Child Panel Area"),
    "OnWheelDown",(guiObj) => LogEvent("[Child Panel] Scrolled DOWN on Child Panel Area")
))

; B. Child Controls Registration
childTracker.RegisterControl(childBtn, Map(
    "OnEnter",  (ctrl) => LogEvent("[Child Control] Hovering Child Button"),
    "OnLClick", (ctrl) => MsgBox("Child Panel Button Clicked!", "GuiTracker Child"),
    "OnWheelUp",  (ctrl) => LogEvent("[Child Button] Scrolled UP on Child Button"),
    "OnWheelDown",(ctrl) => LogEvent("[Child Button] Scrolled DOWN on Child Button")
))

childTracker.RegisterControl(childEdit, Map(
    "OnEnter",  (ctrl) => LogEvent("[Child Control] Hovering Child Edit Field")
))
*/