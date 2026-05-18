/************************************************************************
 * @description Custom MsgBox with some automatico Error detections
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/05/14
 * @version 1.1.0
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
    MyGuiOptions := "+LastFound -MinimizeBox"
    static Result := ""

    ; Check DarkMode
    if (IsSet(CurrentActualTheme) && CurrentActualTheme == "Dark") {
        MyGui := DarkGui(MyGuiOptions, MyGuiTitle)
    } else {
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
    }

    ; Define layout constants
    FontSize            := 12
    btnAlign            := "Auto"
    btnGap              := 10
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30
    btnW                := 80
    GuiMinWidth         := 400
    GuiMaxWidth         := 1000
    GuiMinHeight        := 180
    GuiMaxHeight        := 800

    MyGui.SetFont("s" FontSize)

    ; Finding the caller
    err := Error()
    if (err.HasProp("Stack") && err.Stack != "" && Debug) {
        stack := err.Stack
        lines := StrSplit(stack, "`n")
        if (lines.Length >= 2) {
            ; Use RegEx for more reliable parsing of the "File (Line) : [Function]" format
            if RegExMatch(lines[2], "(.*) \((\d+)\)", &Match) {
                FullFile := Match[1]
                LineNum  := Match[2]
                SplitPath(FullFile, &FileName)
                ;CallerText := FileName " line: " LineNum
                CallerText := FullFile "`nline: " LineNum
                caller := MyGui.AddText("Left y+15", CallerText)
                ;caller.SetFont("underline")
                caller.OnEvent("Click", (*) => (A_Clipboard := CallerText, ToolTip("Copied"), SetTimer(() => ToolTip(), -1000)))
            }
        }
    }

    ; Message
    txt := MyGui.AddText("Left y+25", Text)

    ; Check if errorValue came from a catch
    if IsSet(errorValue){
/* 
        errorValueText := ("Error: " errorValue.Message "`n"
            "File: " errorValue.File "`n"
            "Line: " errorValue.Line "`n"
            "Extra: " errorValue.Extra
        )
 */
        try errorValueText := "Error `n"
        try errorValueText := errorValueText "Error Message: " errorValue.Message "`n"
        try errorValueText := errorValueText "Error File: " errorValue.File "`n"
        try errorValueText := errorValueText "Error Line: " errorValue.Line "`n"
        try errorValueText := errorValueText "Error Extra: " errorValue.Extra "`n"


        GotError := MyGui.AddText("Left y+15", errorValueText)
;        GotError.SetFont("underline")
        GotError.OnEvent("Click", (*) => (A_Clipboard := errorValueText, ToolTip("Copied"), SetTimer(() => ToolTip(), -1000)))
    }

    ButtonsStrings := (InStr(Buttons, "OKCancel"))    ? ["&OK", "&Cancel"] :
                  (InStr(Buttons, "RetryCancel")) ? ["&Retry", "&Cancel"] :
                  (InStr(Buttons, "ContinueExit")) ? ["&Continue", "&Exit"] :
                  (InStr(Buttons, "YesNo"))       ? ["&Yes", "&No"] : ["&OK"]

    BtnObjects := []

    ; Buttons
    if ButtonsStrings{
        for index, btnName in ButtonsStrings {
            xPos := (index = 1) ? "xm" : "x+" btnGap
            yPos := (index = 1) ? "y+40" : "yp"
            btn := MyGui.AddButton("w" btnW " h30 " xPos " " yPos, btnName)
            btn.OnEvent("Click", (GuiBtn, *) => (Result := StrReplace(GuiBtn.Text, "&"), MyGui.Destroy()))
            if (index = 1)
                btn.Opt("+Default")
            BtnObjects.Push(btn)
        }
    }

    ; Calculate dimensions
    MyGui.Show("Hide") 
    MyGui.GetClientPos(,, &guiW, &guiH)
    
    finalW := Max(Min(guiW, GuiMaxWidth), GuiMinWidth)
    finalH := Max(Min(guiH, GuiMaxHeight), GuiMinHeight)

    if ButtonsStrings{
        ; Positioning buttons
        totalBtnW := (BtnObjects.Length * btnW) + ((ButtonsStrings.Length - 1) * btnGap)

        if btnAlign = "Auto" {
            if (BtnObjects.Length = 1) {
                btnAlign := "Center"
            } else if (BtnObjects.Length > 1){
                btnAlign := "Right"
            }
        }

        switch btnAlign {
            case "Left":            startX := MyGui.MarginX
            case "Center":          startX := (finalW - totalBtnW) / 2
            case "Right":           startX := finalW - totalBtnW - MyGui.MarginX
        }

        for index, btnObj in BtnObjects {
            newX := startX + ((index - 1) * (btnW + btnGap))
            ; Place buttons exactly MarginY away from the bottom edge
            newY := finalH - MyGui.MarginY - 30 
            btnObj.Move(newX, newY)
        }
    }
    MyGui.OnEvent("Close", (*) => MyGui.Destroy())
    MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
    MyGui.Show("w" finalW " h" finalH " Center")
    
    WinWaitClose(MyGui)
    return Result
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