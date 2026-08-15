/************************************************************************
 * @description QOL helper functions
 * @author Melo (melo@meloprofessional.com) and Pj
 * @date 2026/08/12
 * @version 1.0.0
 ***********************************************************************/


/**
 * @description {@link IsFunctionDefined|_HelperFuncs.ahk}
 * Check if a function is available, returning true | false
 * @param {(String)} [FunctionName]
 * The name of the function to test
 * @returns {(Boolean)}
 * - `1` = The function is available.
 * - `0` = The function is not available.
 * @example <caption>Check if ShowHelpGUI() is available and uses it</caption>
 * if IsFunctionDefined("ShowHelpGUI")
 *     MoreMenu.Add("Help", (*) => %"ShowHelpGUI"%())
 */
IsFunctionDefined(FunctionName) {
        try return HasMethod(%FunctionName%)
        return false
    }


/**
 * @description {@link ReloadClean|_HelperFuncs.ahk}
 * Reload current App with clean environment. Option to send arguments.
 * @param {(String)} [args*]
 * First is the name of the function you and to call after reload, ie: "MyFuntcion"
 * then the n parameters to send do the function, ie: "foo", "bar"
 * @example <caption>Reload current App</caption>  
 * ReloadClean()
 * @example <caption>Reload current App sending 2 arguments</caption>  
 * ReloadClean("showGUI", "foo")
 */
ReloadClean(args*) {
    argString := ""
    for arg in args {
        if IsSet(arg) && arg != "" {
            argString .= ' "' arg '"'
        } else {
            argString .= ' "<unset>"'
        }
    }

    if DllCall("userenv\CreateEnvironmentBlock", "Ptr*", &lpEnv:=0, "Ptr",0, "Int",0) {
        si := Buffer(siSize := A_PtrSize == 8 ? 104 : 68, 0), NumPut("UInt", siSize, si)
        pi := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
        cmd := (A_IsCompiled ? '"' A_ScriptFullPath '" /force' : '"' A_AhkPath '" /force "' A_ScriptFullPath '"') argString

        if DllCall("CreateProcessW", "Ptr",0, "Str",cmd, "Ptr",0, "Ptr",0, "Int",0, "UInt",0x400, "Ptr",lpEnv, "Ptr",0, "Ptr",si, "Ptr",pi)
            ExitApp()
        DllCall("userenv\DestroyEnvironmentBlock", "Ptr", lpEnv)
    }
    Reload()
}


/**
 * @description {@link ReloadWithArgs|_HelperFuncs.ahk}
 * Regular Reload current App with arguments. No Clean environment.
 * You need CheckReloadArgs to handle mutiples arguments.
 * @param {(String)} [args*]
 * First is the name of the function you and to call after reload, ie: "MyFuntcion"
 * then the n parameters to send do the function, ie: "foo", "bar"
 * @example <caption>Reload current App sending 3 arguments</caption>  
 * ReloadWithArgs("showGUI", , "foo")
 */
ReloadWithArgs(args*) {
    argString := ""
    for arg in args {
        if IsSet(arg) && arg != "" {
            argString .= ' "' arg '"'
        } else {
            argString .= ' "<unset>"'
        }
    }

    if A_IsCompiled {
        Run('"' A_ScriptFullPath '" /restart' argString)
    } else {
        Run('"' A_AhkPath '" /restart "' A_ScriptFullPath '"' argString)
    }
    ExitApp()
}


/**
 * @description {@link CheckReloadArgs|_HelperFuncs.ahk}
 * Use this function after loading your code to check if there was arguments to dynamically call functions with parameters.
 * If "signal-update-success" was received at arg[1], does nothing.
 * @example <caption>Check if the App received arguments and call function (arg[1]) with parameters (arg[n]).</caption>  
 * CheckReloadArgs()
 */
CheckReloadArgs() {
	if A_Args.Length && !RegExMatch(A_Args[1], "i)^--signal-update-success=") {
		targetFuncName := A_Args[1]
		try {
			fnParams := A_Args.Clone()
			fnParams.RemoveAt(1)
			for index, param in fnParams {
				if (param = "<unset>") {
					fnParams.Delete(index)
				}
			}
			%targetFuncName%(fnParams*)
		} catch Any as e {
			throw e
		}
	}
}


/**
 * @description {@link DPIScale|_HelperFuncs.ahk}
 * Returns DPI Scaled value
 * @param {(Number)} [value]
 * @returns {(Integer)}
 * Returns the rounded value scaled to current DPI
 * @example <caption>Show a GUI properly scaled.</caption>  
 * MyGui := Gui("AlwaysOnTop", A_ScriptName)
 * MyGui.SetFont("s" DPIScale(10))
 * MyGui.Add("Text", "w" DPIScale(2000), "This is a text")
 * MyGui.Show("w" DPIScale(600) " h" DPIScale(200))
 */
DPIScale(value) {
	return Round(value * (A_ScreenDPI / 96))
}


/**
 * @description {@link MsgBoxCustom|_HelperFuncs.ahk}
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
 * answer := MsgBoxCustom("Continue?", "Question", "YesNo")
 * @example <caption>Show a Message Box asking to Reload</caption>
 * if (MsgBoxCustom("Reload?", App.Name, "YesNo") = "Yes")
 *    Reload
 * @example <caption>Use in a ternary</caption>
 * MsgBoxCustom("AccessStatus Denied", , "RetryCancel") = "Cancel" ? ExitApp() : Reload()
 * @example <caption>Catch errors</caption>  
 * try {
 * 	foo()
 * } catch as err {
 *     MsgBoxCustom("This in an error:",,,err)
 * }
*/
MsgBoxCustom(Text := "Message", Title := "Warning", Buttons := "OK", errorValue?) {
    MyGuiTitle := Title
    MyGuiOptions := "-MinimizeBox"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)

    ; Layout Configuration
    FontSize        := DPIScale(10)
    btnGap          := DPIScale(10)
    btnW            := DPIScale(90)
    btnH            := DPIScale(30)
    MyGui.MarginX   := DPIScale(30)
    MyGui.MarginY   := DPIScale(25)
    GuiMinWidth     := DPIScale(300)
    GuiMaxWidth     := DPIScale(660)
    
    static Result := ""
    Result := "" ; Reset to prevent click-bleeding

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
    txtCtrl := MyGui.AddText("Left w" (GuiMinWidth - DPIScale(60)), Text)

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

        GotError := MyGui.AddEdit("Left r" LineCount " w" (GuiMaxWidth - DPIScale(60)) " ReadOnly -E0x200 -WantReturn", errorValueText)
        GotError.Move(,, GuiMinWidth - 60, EditHeight)
        
        ; Copies ALL messages combined to the clipboard
        GotError.OnEvent("Focus", (*) => (A_Clipboard := FullReportText, ToolTip("Copied Full Report"), SetTimer(() => ToolTip(), -1000)))
    }

    ; Parse Buttons
ButtonsStrings := (InStr(Buttons, "ReloadExitContinue")) ? ["&Reload", "&Exit", "&Continue"] :
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

/**
 * @description {@link OnError|_HelperFuncs.ahk}
 * Handle errors calling OnErrorCustom and then MsgBoxCustom.
 * This is auto activated.
 */
OnError(OnErrorCustom)


/**
 * @description {@link OnErrorCustom|_HelperFuncs.ahk}
 * Handle errors calling MsgBoxCustom.
 */
OnErrorCustom(Exception, Mode) {
    ErrorType := Type(Exception)
    
    DynamicText := "An unhandled " ErrorType " occurred!`n`n"
    DynamicText .= "What happened: " Exception.Message "`n"
    if (Exception.Extra) {
        DynamicText .= "Specifically: " Exception.Extra "`n"
    }
    DynamicText .= "`nExecution Mode: " (Mode == "Exit" ? "The thread will exit." : "The thread will continue.")
    
    ; PASS THE NEW THREE-BUTTON COMBO HERE
    Result := MsgBoxCustom(DynamicText, ErrorType, "ReloadExitContinue", Exception)
    
    ; HANDLE THE USER'S CHOICES
    if (Result == "Reload") {
        Reload()
    } else if (Result == "Exit") {
        ExitApp()
    }    
    return 1 ; Suppress standard AHK error window
}

/**
 * @description {@link SoudPlayWin|_HelperFuncs.ahk}
 * Play Windows Sound or audio file.
 * @param {(String)} [audiofile]
 * Either a windows sound ie: "Windows Default"
 * either a file path ie: A_ScriptDir "\assets\audios\off_260702.wav"
 * @param {(Integer)} [timer]
 * For how long milliseconds to wait to stop playing (defaults to 5000)
 * @example <caption>Plays default Windows notification</caption>
 * SoundPlayWin("Windows Notify")
 * @example <caption>Plays an audio file.</caption>
 * SoundPlayWin(A_ScriptDir "\assets\audios\on_260702.wav")
 * @example <caption>Plays a long length audio</caption>
 * SoundPlayWin(A_ScriptDir "\assets\audios\longaudio.wav", 0)
 */
SoundPlayWin(audiofile := "Windows Notify", timer := 5000) {
    ; If relative/short name passed, resolve to standard Windows Media path
    if !InStr(audiofile, "\")
        audiofile := A_WinDir "\Media\" audiofile ".wav"

    ; SND_FILENAME (0x20000) | SND_ASYNC (0x1) | SND_NODEFAULT (0x2) = 0x20003
    ; Plays sound in background and avoids error beeps if file is missing
    try DllCall("Winmm.dll\PlaySoundW", "Str", audiofile, "Ptr", 0, "UInt", 0x20003)

    ; Schedule file release if timer is provided
    if (timer > 0)
        SetTimer(ReleaseFile, -timer)

    ReleaseFile() {
        ; Passing 0 as the path cleanly stops playback and releases file handles
        try DllCall("Winmm.dll\PlaySoundW", "Ptr", 0, "Ptr", 0, "UInt", 0x0)
    }
}
