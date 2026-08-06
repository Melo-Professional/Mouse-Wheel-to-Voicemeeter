/************************************************************************
 * @description Autod Updater
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/06
 * @version 1.3.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

StartAutoUpdater() {
	global FirstRun, Updater

	if IsSet(AutoUpdater) && App.HasOwnProp("Github") && App.Github != "" && App.Github != "https://github.com/Melo-Professional/" {
		if !IsSet(FirstRun) {
			FirstRun := false
		}
		Updater := AutoUpdater(App)
		Updater.CheckOnStartup(FirstRun)
	}
}

for arg in A_Args {
	if RegExMatch(arg, "i)^--signal-update-success=(.+)$", &match) {
		;signalFileUpdate := Trim(match[1], '"')
		signalFile := Trim(match[1], '"')
		try FileOpen(signalFile, "w").Write("OK")
		break
	}
}

class AutoUpdater {
    App := ""
    LatestVersion := ""
    DownloadUrl := ""
    
    static Call(args*) {
        return super.Call(args*)
    }

    __New(appObject) {
        this.App := appObject
        if !this.App.HasOwnProp("UpdateAuto")
            this.App.UpdateAuto := true
        if !this.App.HasOwnProp("UpdateFrequencyDays")
            this.App.UpdateFrequencyDays := 7
        if !this.App.HasOwnProp("UpdateLastCheck") || this.App.UpdateLastCheck == ""
            this.App.UpdateLastCheck := "1970-01-01"

		if Debug {
			tooltip("`n" . "has update auto: " this.App.HasOwnProp("UpdateAuto") .
					"`n" . "update auto: " this.App.UpdateAuto .
					"`n" . "has update frequency days: " this.App.HasOwnProp("UpdateFrequencyDays") .
					"`n" . "frequency days: " this.App.UpdateFrequencyDays .
					"`n" . "has update last check: " this.App.HasOwnProp("UpdateAuto") .
					"`n" . "last check: " this.App.UpdateLastCheck .
					"`n ."
			)
		}
    }

    CheckOnStartup(isFirstRun := false) {
        if (!this.App.UpdateAuto || !this.App.HasOwnProp("Github") || this.App.Github == "")
            return
            
        lastCheck := StrReplace(this.App.UpdateLastCheck, "-", "") . "000000"
        if (StrLen(lastCheck) < 14 || !IsTime(lastCheck))
            lastCheck := "19700101000000"

        diffDays := DateDiff(A_Now, lastCheck, "Days")
        
        if (isFirstRun || diffDays >= this.App.UpdateFrequencyDays) {
            SetTimer(() => this.PerformStartupCheck(isFirstRun), -100)
        }
    }

    PerformStartupCheck(isFirstRun) {
        hasUpdate := this.CheckForUpdates(true)
        if (hasUpdate) {
            if isFirstRun {
                this.ShowUpdaterGUI()
            } else {
                this.ApplyUpdate(true)
            }
        }
    }

    CheckForUpdates(silent := false) {
        if (!this.App.HasOwnProp("Github") || this.App.Github == "") {
            if !silent
                MsgBox("No GitHub repository specified for this app.", "Update Error", "48")
            return false
        }

        if !RegExMatch(this.App.Github, "github\.com/([^/]+)/([^/]+)", &m) {
            if !silent
                MsgBox("Invalid GitHub URL format.", "Update Error", "48")
            return false
        }
        
        apiUrl := "https://api.github.com/repos/" . m[1] . "/" . m[2] . "/releases/latest"

        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open("GET", apiUrl, true)
            whr.SetRequestHeader("User-Agent", "AHK-AutoUpdater")
            whr.Send()
            whr.WaitForResponse()
            
            if (whr.Status != 200)
                throw Error("HTTP " . whr.Status)
                
            json := whr.ResponseText
            
            if RegExMatch(json, '"tag_name"\s*:\s*"([^"]+)"', &tagMatch)
                this.LatestVersion := tagMatch[1]

            targetExt := A_IsCompiled ? "\.exe" : "\.ahk"
            
            if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+' . targetExt . ')"', &dlMatch) {
                this.DownloadUrl := dlMatch[1]
            } else if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+\.zip)"', &dlMatch) {
                this.DownloadUrl := dlMatch[1]
            } else if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+)"', &dlMatch) {
                this.DownloadUrl := dlMatch[1]
            } else if RegExMatch(json, '"zipball_url"\s*:\s*"([^"]+)"', &zipMatch) {
                this.DownloadUrl := zipMatch[1]
            }

            this.App.UpdateLastCheck := FormatTime(A_Now, "yyyy-MM-dd")

            if (this.IsNewerVersion(this.App.Version, this.LatestVersion)) {
                return true
            } else if !silent {
                ; MsgBox("You are running the latest version (" . this.App.Version . ").", "Up to Date", "64")
            }
        } catch Error as err {
            if !silent
                MsgBox("Failed to check for updates.`nError: " . err.Message, "Update Error", "48")
        }
        return false
    }

    IsNewerVersion(current, latest) {
        cClean := RegExReplace(current, "[^\d.]")
        lClean := RegExReplace(latest, "[^\d.]")
        
        cParts := StrSplit(cClean, ".")
        lParts := StrSplit(lClean, ".")
        maxParts := Max(cParts.Length, lParts.Length)
        
        Loop maxParts {
            cP := A_Index <= cParts.Length ? Integer(cParts[A_Index]) : 0
            lP := A_Index <= lParts.Length ? Integer(lParts[A_Index]) : 0
            
            if (lP > cP)
                return true
            if (lP < cP)
                return false
        }
        return false
    }

    ApplyUpdate(silent := false) {
        if (this.DownloadUrl == "") {
            if !silent
                MsgBox("No download URL found for this release on GitHub.", "Update Error", "48")
            return
        }

        this.App.UpdateLastCheck := FormatTime(A_Now, "yyyy-MM-dd")
        if (this.App.HasOwnProp("UpdateLastCheck"))
            App.UpdateLastCheck := this.App.UpdateLastCheck
        if (Type(SaveINI) == "Func" || Type(SaveINI) == "Closure")
            SaveINI()

        isZip := RegExMatch(this.DownloadUrl, "i)\.zip(\?|$)") || RegExMatch(this.DownloadUrl, "i)/zipball/")
        
        urlExt := A_IsCompiled ? ".exe" : ".ahk"
        if RegExMatch(this.DownloadUrl, "i)\.([a-z0-9]+)(\?|$)", &extMatch) {
            urlExt := "." . extMatch[1]
        }
        
        dlFile := A_Temp . "\app_update_dl_" . A_TickCount . (isZip ? ".zip" : urlExt)
        targetFile := A_ScriptFullPath
        targetDir := A_ScriptDir
        newExeName := ""
        payloadFile := ""
        extractDir := ""
        sourceDir := ""

        try {
            if !silent
                ToolTip(" `nDownloading update...`n ")
            Download(this.DownloadUrl, dlFile)
            if !silent
                ToolTip()
        } catch Error as err {
            if !silent {
                ToolTip()
                MsgBox("Failed to download update file.`n" . err.Message, "Download Failed", "48")
            }
            return
        }

        ; --- ANTIVIRUS FRIENDLY UNZIP VIA WINDOWS SHELL COM OBJECT ---
        if isZip {
            if !silent
                ToolTip(" `nExtracting update...`n ")
            extractDir := A_Temp . "\ahk_update_ext_" . A_TickCount
            DirCreate(extractDir)
            
            try {
                shell := ComObject("Shell.Application")
                zipFolder := shell.NameSpace(dlFile)
                destFolder := shell.NameSpace(extractDir)
                if (zipFolder && destFolder) {
                    ; 4 = Do not display a progress dialog box
                    ; 16 = Respond with "Yes to All" for any dialog box that is displayed
                    destFolder.CopyHere(zipFolder.Items(), 4 | 16)
                }
            } catch Error as err {
                if !silent
                    MsgBox("Extraction failed: " . err.Message, "Update Error", "48")
                return
            }
            
            try FileDelete(dlFile)

            searchExt := A_IsCompiled ? "exe" : "ahk"
            
            hasRootFile := false
            Loop Files, extractDir . "\*." . searchExt {
                hasRootFile := true
                break
            }
            
            if hasRootFile {
                sourceDir := extractDir
            } else {
                Loop Files, extractDir . "\*", "D" {
                    subDir := A_LoopFileFullPath
                    Loop Files, subDir . "\*." . searchExt, "R" {
                        sourceDir := subDir
                        break 2
                    }
                }
                
                if (sourceDir == "")
                    sourceDir := extractDir
            }

            Loop Files, sourceDir . "\" . A_ScriptName, "R" {
                newExeName := A_LoopFileName
                break
            }

            if (newExeName == "") {
                Loop Files, sourceDir . "\*." . searchExt, "R" {
                    newExeName := A_LoopFileName
                    break
                }
            }

            if !silent
                ToolTip()

            if (newExeName == "") {
                if !silent
                    MsgBox("Failed to locate an updated ." . searchExt . " file inside the downloaded zip archive.", "Update Error", "48")
                try DirDelete(extractDir, true)
                return
            }
        } else {
            payloadFile := dlFile
            
            if RegExMatch(this.DownloadUrl, "[^/]+\.[a-zA-Z0-9]+(?=\?|$)", &fileNameMatch) {
                newExeName := fileNameMatch[0]
            } else {
                newExeName := A_ScriptName
            }
        }

        cmdScript := A_Temp . "\ahk_updater_" . A_TickCount . ".cmd"
        global signalFile := A_Temp . "\ahk_upd_ok_" . A_TickCount . ".tmp"
        pid := ProcessExist()
        
        if !RegExMatch(newExeName, "i)\.(exe|ahk)$") {
            newExeName .= (A_IsCompiled ? ".exe" : ".ahk")
        }

        newTargetPath := targetDir . "\" . newExeName
        
        SplitPath(targetFile, &targetName, &targetDir, &targetExt, &targetNameNoExt)
        backupFileName := targetNameNoExt . "_v" . this.App.Version . "." . targetExt . ".bak"
        backupFilePath := targetDir . "\" . backupFileName
        failedFileName := targetNameNoExt . "_FAILED." . targetExt

        ; --- ANTIVIRUS FRIENDLY BATCH SCRIPT ---
        cmdLines := [
            "@echo off",
            "timeout /t 2 /nobreak > nul",
            
            'if exist "' . backupFilePath . '" del /f /q "' . backupFilePath . '"',
            'if exist "' . targetDir . '\' . failedFileName . '" del /f /q "' . targetDir . '\' . failedFileName . '"',

            'ren "' . targetFile . '" "' . backupFileName . '"'
        ]

        if isZip {
            cmdLines.Push('xcopy /e /y /i /q "' . sourceDir . '\*" "' . targetDir . '" > nul')
            cmdLines.Push('rmdir /s /q "' . extractDir . '"')
        } else {
            cmdLines.Push('move /y "' . payloadFile . '" "' . newTargetPath . '" > nul')
        }

        if A_IsCompiled {
            cmdLines.Push('start "" "' . newTargetPath . '" "--signal-update-success=' . signalFile . '"')
        } else {
            cmdLines.Push('start "" "' . A_AhkPath . '" "' . newTargetPath . '" "--signal-update-success=' . signalFile . '"')
        }
        
        cmdLines.Push('set "counter=0"')
        cmdLines.Push(':check_health')
        cmdLines.Push('timeout /t 1 /nobreak > nul')
        cmdLines.Push('if exist "' . signalFile . '" goto update_success')
        cmdLines.Push('set /a counter+=1')
        cmdLines.Push('if %counter% LSS 8 goto check_health')

        cmdLines.Push(':update_failed')
        cmdLines.Push('if exist "' . newTargetPath . '" ren "' . newTargetPath . '" "' . failedFileName . '"')
        cmdLines.Push('if exist "' . backupFilePath . '" ren "' . backupFilePath . '" "' . targetName . '"')
        cmdLines.Push('msg * "Update failed to launch properly. Restoring previous working version."')
        
        if A_IsCompiled {
            cmdLines.Push('start "" "' . targetFile . '"')
        } else {
            cmdLines.Push('start "" "' . A_AhkPath . '" "' . targetFile . '"')
        }
        cmdLines.Push('goto cleanup')

        cmdLines.Push(':update_success')
        cmdLines.Push('if exist "' . signalFile . '" del /f /q "' . signalFile . '"')
        cmdLines.Push('if exist "' . backupFilePath . '" del /f /q "' . backupFilePath . '"')

        cmdLines.Push(':cleanup')
        cmdLines.Push('del "%~f0"')

        cmdContent := ""
        for line in cmdLines
            cmdContent .= line . "`r`n"

        FileOpen(cmdScript, "w").Write(cmdContent)
        
        Run(A_ComSpec . ' /c "' . cmdScript . '"', , "Hide")
        ExitApp()
    }
/* 
	ShowUpdaterGUI1() {
        hasUpdate := (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion))

        MyGuiTitle := App.Name . " - Update"
        MyGuiOptions := "+LastFound -SysMenu"
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
        MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
        offset := 5

        if IsFunctionDefined("CustomTitleBar") {
            MyGui.Opt("-Caption")
            titlebar := %"CustomTitleBar"%.Attach(MyGui, {
                Title: MyGuiTitle,
                ShowIcon: true,
                Min: false,
                Max: false,
                Close: true
            })
            offset := 40
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
        }

        MyGui.MarginX := 34
        MyGui.MarginY := 20

		MyGui.SetFont("s" Settings.GuiFontSizeExtraBig, Settings.GuiFontName)
        txtBannerTitle := MyGui.AddText("vStrong_01 xm w320", "")
		MyGui.SetFont("s" Settings.GuiFontSizeBig, Settings.GuiFontName)
        txtBannerSub   := MyGui.AddText("xm w320 y+2", "")

        UpdateBannerUI() {
            if (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion)) {
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c0x008000", Settings.GuiFontName)
                txtBannerTitle.Value := "A new update is available!"
                txtBannerSub.SetFont("s" Settings.GuiFontSizeBig " Norm", Settings.GuiFontName)
                txtBannerSub.Value := "Version " . this.LatestVersion . " is ready to install."
            } else if (this.LatestVersion != "") {
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c0x2B579A", Settings.GuiFontName)
                txtBannerTitle.Value := "✓ You're up to date"
                txtBannerSub.SetFont("s" Settings.GuiFontSizeBig " Norm", Settings.GuiFontName)
                txtBannerSub.Value := "You are running the latest version."
            } else {
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c0x8b8b8b", Settings.GuiFontName)
                txtBannerTitle.Value := "Update Preferences"
                txtBannerSub.SetFont("s" Settings.GuiFontSizeBig " Norm", Settings.GuiFontName)
                txtBannerSub.Value := "Check and manage application updates."
            }
			MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
        }

        UpdateBannerUI()

        MyGui.SetFont("s9 Norm", "Segoe UI")
        
        MyGui.AddText("xm w120 y+40 c0x666666", "Current Version:")
        MyGui.SetFont("s9 bold")
        MyGui.AddText("vStrong_03 x+10 w180 c0x222222", this.App.Version)

        MyGui.SetFont("s9 Norm")
        MyGui.AddText("xm y+10 w120 c0x666666", "Latest Version:")
        MyGui.SetFont("s9 bold")
        lblLatest := MyGui.AddText("vStrong_04 x+10 w180 c0x222222", this.LatestVersion != "" ? this.LatestVersion : "Not checked")

        MyGui.SetFont("s9 Norm")
        MyGui.AddText("xm y+10 w120 c0x666666", "Last Checked:")
        lblLastCheck := MyGui.AddText("x+10 w180 c0x222222", this.App.UpdateLastCheck)

        chkAuto := MyGui.AddCheckbox("xm y+40 Checked" . (this.App.UpdateAuto ? "1" : "0"), " &Enable Automatic Updates")
        
        lblFreq := MyGui.AddText("xm y+14 c0x444444", "Check frequency (days):")
        numFreq := MyGui.AddEdit("x+12 w60 Number Center", this.App.UpdateFrequencyDays)
        updUpDown := MyGui.AddUpDown("Range1-90", this.App.UpdateFrequencyDays)

        ToggleFreqControls(enabled) {
            lblFreq.Enabled := enabled
            numFreq.Enabled := enabled
            updUpDown.Enabled := enabled
        }
        
        ToggleFreqControls(this.App.UpdateAuto)
        chkAuto.OnEvent("Click", (*) => ToggleFreqControls(chkAuto.Value != 0))

        btnCheck := MyGui.AddButton("xm y+40 w155 h32", "&Check for Updates")
        btnUpdate := MyGui.AddButton("x+10 w155 h32 " . (hasUpdate ? "" : "Disabled"), "&Install Update")

        btnSave := MyGui.AddButton("xm y+12 w320 h34", "&Save && Close")
		btnCheck.OnEvent("Click", _CheckUpdate)
        btnUpdate.OnEvent("Click", (*) => this.ApplyUpdate(false))

        btnSave.OnEvent("Click", (*) => (
            this.App.UpdateAuto := (chkAuto.Value != 0),
            this.App.UpdateFrequencyDays := Integer(numFreq.Value),
            App.UpdateAuto := this.App.UpdateAuto,
            App.UpdateFrequencyDays := this.App.UpdateFrequencyDays,
            App.UpdateLastCheck := this.App.UpdateLastCheck,
            (Type(SaveINI) == "Func" || Type(SaveINI) == "Closure") ? SaveINI() : "",
			CleanDestroy()
        ))

		if IsFunctionDefined("ApplyThemeToGui"){
			%"ApplyThemeToGui"%(MyGui)
			%"WatchedGUIs"%.Push(MyGui)
		}

		MyGui.OnEvent("Close", CleanDestroy)
		MyGui.OnEvent("Escape", CleanDestroy)

        MyGui.Show()
		_CheckUpdate()

		_CheckUpdate(*) {
            btnCheck.Enabled := false,
            btnCheck.Text := "Checking...",
            hasUpdate := this.CheckForUpdates(false),
            lblLastCheck.Value := this.App.UpdateLastCheck,
            lblLatest.Value := this.LatestVersion != "" ? this.LatestVersion : "Unknown",
            UpdateBannerUI(),
            btnUpdate.Enabled := hasUpdate,
            btnCheck.Text := "&Check for Updates",
            btnCheck.Enabled := true
		}

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
 */

	ShowUpdaterGUI() {
		hasUpdate := (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion))

		MyGuiTitle := App.Name . " - Update"
		MyGuiOptions := "+LastFound"
		MyGui := Gui(MyGuiOptions, MyGuiTitle)
		MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
		offset := 10

		UseAcrylicGUI := false
		if IsFunctionDefined("FrostedTheme") {
			UseAcrylicGUI := true
			offset := 50
		}

		if IsFunctionDefined("CustomTitleBar") {
			MyGui.Opt("-Caption")
			titlebar := %"CustomTitleBar"%.Attach(MyGui, {
				Title: "",
				ShowIcon: false,
				Min: true,
				Max: false,
				Close: true
			})
			offset := 50
			DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
		}

		TextNormalColor := "CCCCCC"
		TextHoverColor  := "FFFFFF"
		BGroundNormalColor  := "1b1b1b"
		BGroundHoverColor  := "313131"
		isHovering := false

		GuiWidth            := 340
		BtnWidth            := 100
		MyGui.MarginX       := 50
		MyGui.MarginY       := 30

		try {
			MyGui.Add("Picture", "xm y" offset " w32 h32", App.Icon)
		} catch {
			MyGui.SetFont("s15 w500")
			MyGui.Add("Text", "y" offset " w32 h32", "[ i ]")
		}

		MyGui.SetFont("s" Settings.GuiFontSizeBig " w700")
		MyGui.Add("Text", "x+15 yp vStrong_Title", App.Name)

		MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")
		MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)

		MyGui.SetFont("s" Settings.GuiFontSizeExtraBig, Settings.GuiFontName)
        txtBannerTitle := MyGui.AddText("vStrong_01 xm y+40 w320", "")
		MyGui.SetFont("s" Settings.GuiFontSizeBig, Settings.GuiFontName)
        txtBannerSub   := MyGui.AddText("xm w320 y+2", "")

        UpdateBannerUI() {
            if (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion)) {
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c0x008000", Settings.GuiFontName)
                txtBannerTitle.Value := "A new update is available!"
                txtBannerSub.SetFont("s" Settings.GuiFontSizeBig " Norm", Settings.GuiFontName)
                txtBannerSub.Value := "Version " . this.LatestVersion . " is ready to install."
            } else if (this.LatestVersion != "") {
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c0x2B579A", Settings.GuiFontName)
                txtBannerTitle.Value := "✓ You're up to date"
                txtBannerSub.SetFont("s" Settings.GuiFontSizeBig " Norm", Settings.GuiFontName)
                txtBannerSub.Value := "You are running the latest version."
            } else {
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c0x8b8b8b", Settings.GuiFontName)
                txtBannerTitle.Value := "Update Preferences"
                txtBannerSub.SetFont("s" Settings.GuiFontSizeBig " Norm", Settings.GuiFontName)
                txtBannerSub.Value := "Check and manage application updates."
            }
			MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
        }

        UpdateBannerUI()

		MyGui.SetFont("s" Settings.GuiFontSizeSmall " Norm w100")
		MyGui.AddText("xm w120 y+40", "Current Version:")

		MyGui.SetFont("s" Settings.GuiFontSizeMedium " Bold w800")
		MyGui.AddText("vStrong_03 x+10 w180", this.App.Version)

		MyGui.SetFont("s" Settings.GuiFontSizeSmall " Norm w100")
		MyGui.AddText("xm y+10 w120", "Latest Version:")

		MyGui.SetFont("s" Settings.GuiFontSizeMedium " Bold w800")
		lblLatest := MyGui.AddText("vStrong_04 x+10 w180", this.LatestVersion != "" ? this.LatestVersion : "Not checked")

		MyGui.SetFont("s" Settings.GuiFontSizeSmall " Norm w100")
		MyGui.AddText("xm y+10 w120", "Last Checked:")

		lblLastCheck := MyGui.AddText("x+10 w180", this.App.UpdateLastCheck)

		MyGui.SetFont("s" Settings.GuiFontSizeMedium " Norm")
        chkAuto := MyGui.AddCheckbox("xm y+40 Checked" . (this.App.UpdateAuto ? "1" : "0"))
		MyGui.AddText("x+0", "Enable Automatic Updates")
        
        lblFreq := MyGui.AddText("xm y+12 h30 0x0200", "Check frequency (days)")
		MyGui.SetFont("s" Settings.GuiFontSizeExtraBig " Bold w800")
        numFreq := MyGui.AddEdit("x+40 w60 h30 0x0200 Number Center", this.App.UpdateFrequencyDays)
        updUpDown := MyGui.AddUpDown("Range1-90", this.App.UpdateFrequencyDays)
		MyGui.SetFont("s" Settings.GuiFontSizeMedium " Norm")

        ToggleFreqControls(enabled) {
            lblFreq.Enabled := enabled
            numFreq.Enabled := enabled
            updUpDown.Enabled := enabled
        }

        ToggleFreqControls(this.App.UpdateAuto)
        chkAuto.OnEvent("Click", (*) => ToggleFreqControls(chkAuto.Value != 0))

		MyGui.SetFont("s" Settings.GuiFontSizeMedium " Norm w300", Settings.GuiFontName)
        btnX := (GuiWidth - BtnWidth) // 2

		if UseAcrylicGUI {
			MyGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
			btnUpdate := MyGui.Add("Text", "x" btnX " y+40 w" BtnWidth " h30 Center 0x0200 Background" BGroundNormalColor " +Border", "Install")
			btnUpdate.BypassTheme := true
		} else {
			MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
			btnUpdate := MyGui.AddButton("x" btnX " y+40 w" BtnWidth " h30 Default " . (hasUpdate ? "" : "Disabled"), "&Install")
		}

		btnUpdate.OnEvent("Click", (*) => (hasUpdate ? this.ApplyUpdate(false) : ""))
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

		MyGui.Show("w" GuiWidth)
		UpdateBannerUI()

		_CheckUpdate()

		_CheckUpdate(*) {
            hasUpdate := this.CheckForUpdates(false)
            lblLastCheck.Value := this.App.UpdateLastCheck
            lblLatest.Value := this.LatestVersion != "" ? this.LatestVersion : "Unknown"
            UpdateBannerUI()
            try btnUpdate.Enabled := hasUpdate
		}

		if (App.Github || UseAcrylicGUI) {
			if IsSet(MessageManager) {
				MessageManager.Register(0x0200, OnMouseMoveMyGui)
			} else {
				OnMessage(0x0200, OnMouseMoveMyGui)
			}
		}

		OnMouseMoveMyGui(wParam, lParam, msg, hwnd) {
			try {
				if (!btnUpdate)
					return
			} catch {
				return
			}
			
			if (hwnd == btnUpdate.Hwnd) {
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
				if UseAcrylicGUI {
					ctrl.SetFont("c" TextHoverColor)
					ctrl.Opt("+Background" BGroundHoverColor)
				}
			}
		}    

		OnMouseLeaveMyGui(wParam, lParam, msg, hwnd) {
			try {
				if (hwnd == btnUpdate.Hwnd && UseAcrylicGUI) {
					ctrl := GuiCtrlFromHwnd(hwnd)
					ctrl.SetFont("c" TextNormalColor)
					ctrl.Opt("+Background" BGroundNormalColor)
					isHovering := false
				}
			}
		}

		SaveValues(*) {
            this.App.UpdateAuto := (chkAuto.Value != 0)
            this.App.UpdateFrequencyDays := Integer(numFreq.Value)
            App.UpdateAuto := this.App.UpdateAuto
            App.UpdateFrequencyDays := this.App.UpdateFrequencyDays
            App.UpdateLastCheck := this.App.UpdateLastCheck
            (Type(SaveINI) == "Func" || Type(SaveINI) == "Closure") ? SaveINI() : ""
		}

		CleanDestroy(*) {
			SaveValues()
			if IsSet(MessageManager) {
				MessageManager.Unregister(0x0200, OnMouseMoveMyGui)
				MessageManager.Unregister(0x02A3, OnMouseLeaveMyGui)
			} else {
				OnMessage(0x0200, OnMouseMoveMyGui, 0)
				OnMessage(0x02A3, OnMouseLeaveMyGui, 0)
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
}