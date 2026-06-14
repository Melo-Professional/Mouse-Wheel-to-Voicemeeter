/************************************************************************
 * @description Custom MsgBox with some automatico Error detections
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/29
 * @version 1.4.0
 ***********************************************************************/

/**
 * Custom MsgBox replacement for AHK v2
 * Syntax: MsgBoxCustom(Text, Title, Options)
 * Returns: The text of the button pressed (e.g., "Retry", "Cancel", "OK")
 */

/**
 * @description {@link MsgBoxCustom|GuiMsgBoxCustom.ahk}
 * Displays a Custom Message Box. Useful for keeping your custom icon and better control of your GUIs.
 * @param {(String)} [Text]
 * @param {(String)} [Title]
 * @param {"OKCancel"|"RetryCancel"|"ContinueExit"|"YesNo"|"OK"} [Options]
 * @param {(ValueError)} [err ValueError]
 * @returns {(String)}
 * Returns the button pressed by the user.
 * @example <caption>Show a Message Box with "This is a message" with a OK button.</caption>  
 * MsgBoxCustom("This is a message")
 * @example <caption>Show a Message Box asking "Continue?", a title "Question" with buttons Yes and No.</caption>  
 * MsgBoxCustom("Continue?", "Question", "YesNo")
 */
MsgBoxCustom(Text := "Message", Title := "Warning", Buttons := "OK", errorValue?) {
    MyGuiTitle := Title
;    MyGuiOptions := "+LastFound -MinimizeBox +AlwaysOnTop"
    ;MyGuiOptions := "+LastFound -MinimizeBox"
    MyGuiOptions := "-MinimizeBox"
    static Result := ""
    Result := "" ; Reset to prevent click-bleeding
 
    MyGui := Gui(MyGuiOptions, MyGuiTitle)

    ; Layout Configuration
    FontSize        := 11
    btnGap          := 10
    btnW            := 90
    btnH            := 30
    MyGui.MarginX   := 30
    MyGui.MarginY   := 25
    GuiMinWidth     := 500
    GuiMaxWidth     := 900
    
    MyGui.SetFont("s" FontSize, "Segoe UI")

; 1. Display Caller Link (Debug Mode)
    err := Error()
    if (err.HasProp("Stack") && err.Stack != "" && (IsSet(Debug) ? Debug : false)) {
        lines := StrSplit(err.Stack, "`n")
        if (lines.Length >= 2 && RegExMatch(lines[2], "(.*) \((\d+)\)", &Match)) {
            CallerText := Match[1] "`nline: " Match[2]
            caller := MyGui.AddText("Left", CallerText)
            caller.SetFont("underline")
            
            ; KEEP THIS EVENT INSIDE THE SAFE BLOCK
            caller.OnEvent("Click", (*) => (A_Clipboard := FullReportText, ToolTip("Copied Full Report"), SetTimer(() => ToolTip(), -1000)))
        }
    }

    ; 2. Primary Message Text
    ; Specifying a width constraint allows AHK to calculate text wrapping heights perfectly
    txtCtrl := MyGui.AddText("Left w" (GuiMinWidth - 60), Text)

    ; 3. System Error Block (Using an Edit Control to prevent clipping)
; Create a master report variable starting with the main display text
    FullReportText := Text "`n`n"

    ; 3. System Error Block
    if IsSet(errorValue) {
        errorValueText := "--- SYSTEM ERROR DETAILS ---`n"
        try errorValueText .= "Type: " Type(errorValue) "`n"
        try errorValueText .= "Message: " errorValue.Message "`n"
        try errorValueText .= "File: " errorValue.File "`n"
        try errorValueText .= "Line: " errorValue.Line "`n"
        if (errorValue.Extra != "")
            try errorValueText .= "Extra: " errorValue.Extra "`n"
        
        if errorValue.HasProp("Stack") && errorValue.Stack != "" {
            errorValueText .= "`n--- STACK TRACE ---`n" errorValue.Stack "`n"
        }

        ; Append the detailed error text to our master report
        FullReportText .= errorValueText

        LineCount := StrSplit(errorValueText, "`n").Length
        EditHeight := Min(Max(LineCount * 20, 100), 350)

        GotError := MyGui.AddEdit("Left r" LineCount " w" (GuiMaxWidth - 60) " ReadOnly -E0x200 -WantReturn", errorValueText)
        GotError.Move(,, GuiMinWidth - 60, EditHeight)
        
        ; Copies ALL messages combined to the clipboard
        GotError.OnEvent("Focus", (*) => (A_Clipboard := FullReportText, ToolTip("Copied Full Report"), SetTimer(() => ToolTip(), -1000)))
    }

    ; Parse Buttons
ButtonsStrings := (InStr(Buttons, "ReloadContinueExit")) ? ["&Reload", "&Continue", "&Exit"] :
                      (InStr(Buttons, "OKCancel"))           ? ["&OK", "&Cancel"] :
                      (InStr(Buttons, "RetryCancel"))        ? ["&Retry", "&Cancel"] :
                      (InStr(Buttons, "ContinueExit"))       ? ["&Continue", "&Exit"] :
                      (InStr(Buttons, "YesNo"))              ? ["&Yes", "&No"] : ["&OK"]

    BtnObjects := []
    for index, btnName in ButtonsStrings {
        xPos := (index = 1) ? "xm" : "x+" btnGap
        btn := MyGui.AddButton("w" btnW " h" btnH " " xPos, btnName)
        btn.OnEvent("Click", (GuiBtn, *) => (Result := StrReplace(GuiBtn.Text, "&"), CleanDestroy()))
        if (index = 1)
            btn.Opt("+Default")
        BtnObjects.Push(btn)
    }

    if IsFunctionDefined("ApplyThemeToGui") {
        %"ApplyThemeToGui"%(MyGui)
        %"WatchedGUIs"%.Push(MyGui)
    }
    
    ; 4. Dynamic Window Size Calculation
    MyGui.Show("Hide") 
    MyGui.GetClientPos(,, &guiW, &guiH)
    
    ; Adjust final container geometry safely
    finalW := Max(guiW + MyGui.MarginX, GuiMinWidth)
    finalH := guiH + MyGui.MarginY + btnH

    ; Adjust Text fields to the actual clean width
    ;txtCtrl.Move(,, finalW - (MyGui.MarginX * 2))
    ; Adjust Text fields to the actual clean width and let height auto-adjust
    txtCtrl.Move(,, finalW - (MyGui.MarginX * 2), )
    txtCtrl.Opt("+Redraw")
    if IsSet(GotError)
        GotError.Move(,, finalW - (MyGui.MarginX * 2))

    ; 5. Align and Position Buttons nicely at the footer
    totalBtnW := (BtnObjects.Length * btnW) + ((ButtonsStrings.Length - 1) * btnGap)
    startX := finalW - totalBtnW - MyGui.MarginX ; Default to Right-aligned

    if (BtnObjects.Length = 1)
        startX := (finalW - totalBtnW) / 2      ; Center single buttons

    for index, btnObj in BtnObjects {
        newX := startX + ((index - 1) * (btnW + btnGap))
        newY := finalH - MyGui.MarginY - btnH
        btnObj.Move(newX, newY)
    }

;    MyGui.OnEvent("Close", (*) => MyGui.Destroy())
;    MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
   MyGui.OnEvent("Close", CleanDestroy)
   MyGui.OnEvent("Escape", CleanDestroy)

    ; FORCE FOCUS ON THE FIRST BUTTON (stops the Edit control from auto-selecting)
    if (BtnObjects.Length > 0) {
        BtnObjects[1].Focus()
    }
    
    MyGui.Show("w" finalW " h" finalH " Center")
    
    WinWaitClose(MyGui)
    return Result

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }

   CleanDestroy(*) {
    if IsFunctionDefined("RemoveGuiFromArray")
        %"RemoveGuiFromArray"%(MyGui)

    MyGui.Destroy()
    }

}

/*
 --- Usage Example ---

if (MsgBoxCustom("Access Denied", App.Name, "RetryCancel") = "Cancel") {
    ToolTip "User bailed out!"
    Sleep 2000
    ExitApp
}

if (MsgBoxCustom("Reload?", App.Name, "YesNo") = "Yes")
    Reload

MsgBoxCustom("AccessStatus Denied", , "RetryCancel") = "Cancel" ? ExitApp() : Reload()

MsgBoxCustom("Reload?", , "YesNo") = "Yes" ? Reload() : ""


try {
    val := RegRead("unexistent", "unexistent")
} catch as err {
    MsgBoxCustom("Could not read DND (Do Not Disturb) value from registry",,,err)
}


*/

;MsgBoxCustom("test")


OnErrorCustom(Exception, Mode) {
    ErrorType := Type(Exception)
    
    DynamicText := "An unhandled " ErrorType " occurred!`n`n"
    DynamicText .= "What happened: " Exception.Message "`n"
    if (Exception.Extra) {
        DynamicText .= "Specifically: " Exception.Extra "`n"
    }
    DynamicText .= "`nExecution Mode: " (Mode == "Exit" ? "The thread will exit." : "The thread will continue.")
    
    ; PASS THE NEW THREE-BUTTON COMBO HERE
    Result := MsgBoxCustom(DynamicText, ErrorType, "ReloadContinueExit", Exception)
    
    ; HANDLE THE USER'S CHOICES
    if (Result == "Reload") {
        Reload()
    } else if (Result == "Exit") {
        ExitApp()
    }
    
    return 1 ; Suppress standard AHK error window
}

OnError(OnErrorCustom)