/************************************************************************
 * @description Autod Updater
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/16
 * @version 1.5.103
 ************************************************************************/

#Requires AutoHotkey v2.0

StartAutoUpdater() {
    global FirstRun, Updater

        if IsSet(AutoUpdater) && App.HasOwnProp("GitHubRepo") {
        if !IsSet(FirstRun) {
            FirstRun := false
        }
        Updater := AutoUpdater(App)
        Updater.CheckOnStartup(FirstRun)
    }
}

for arg in A_Args {
    if RegExMatch(arg, "i)^--signal-update-success=(.+)$", &match) {
        signalData := Trim(match[1], '"')
        parts := StrSplit(signalData, "|")
        signalFile := parts[1]
        
        ; Write all files and folders that need to be deleted into the signal file
        try {
            f := FileOpen(signalFile, "w", "UTF-8")
            if (parts.Length >= 2 && parts[2] != "")
                f.WriteLine(parts[2]) ; Backup file path
            if (parts.Length >= 3 && parts[3] != "")
                f.WriteLine(parts[3]) ; Updates directory path
            f.Close()
        }
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
        if (!this.App.UpdateAuto || !this.App.HasOwnProp("GitHubRepo") || this.App.GitHubRepo == "")
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
        if (!this.App.HasOwnProp("GitHubRepo") || this.App.GitHubRepo == "") {
            if !silent
                MsgBox("No GitHub repository specified for this app.", "Update Error", 0x40030)
            return false
        }

        if !RegExMatch(this.App.GitHubRepo, "github\.com/([^/]+)/([^/]+)", &m) {
            if !silent
                MsgBox("Invalid GitHub URL format.", "Update Error", 0x40030)
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
                ; MsgBox("You are running the latest version (" . this.App.Version . ").", "Up to Date", 0x40040)
            }
        } catch Error as err {
            if !silent
                MsgBox("Failed to check for updates.`nError: " . err.Message, "Update Error", 0x40030)
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
                MsgBox("No download URL found for this release on GitHub.", "Update Error", 0x40030)
            return
        }

        this.App.UpdateLastCheck := FormatTime(A_Now, "yyyy-MM-dd")
        if (this.App.HasOwnProp("UpdateLastCheck"))
            App.UpdateLastCheck := this.App.UpdateLastCheck
;        if (Type(SaveINI) == "Func" || Type(SaveINI) == "Closure")
;            SaveINI()

		IsSet(SaveINI) ? SaveINI() : 0

        ; Helper function for PowerShell single-quoted literal escaping
        ps_str(str) => "'" . StrReplace(str, "'", "''") . "'"

        isZip := RegExMatch(this.DownloadUrl, "i)\.zip(\?|$)") || RegExMatch(this.DownloadUrl, "i)/zipball/")
        
        urlExt := A_IsCompiled ? ".exe" : ".ahk"
        if RegExMatch(this.DownloadUrl, "i)\.([a-z0-9]+)(\?|$)", &extMatch) {
            urlExt := "." . extMatch[1]
        }
        
        targetFile := A_ScriptFullPath
        SplitPath(targetFile, &targetName, &targetDir, &targetExt, &targetNameNoExt)
        
        ; Sanitize script name for safe file/folder naming (replaces spaces/special chars with underscores)
        cleanName := RegExReplace(targetNameNoExt, "[^\w\-]", "_")
        
        Global updatesDir := targetDir . "\." . cleanName . "_updates"
        
        if !DirExist(updatesDir)
            DirCreate(updatesDir)
            
        dlFile := updatesDir . "\update-" . this.LatestVersion . (isZip ? ".zip" : urlExt)
        
        payloadFile := ""
        extractDir := ""

        try {
            if !silent
                ToolTip(" `nDownloading update...`n ")
            Download(this.DownloadUrl, dlFile)
            if !silent
                ToolTip()
        } catch Error as err {
            if !silent {
                ToolTip()
                MsgBox("Failed to download update file.`n" . err.Message, "Download Failed", 0x40030)
            }
            return
        }

        ; --- NATIVE .NET ZIP EXTRACTION ---
        if isZip {
            if !silent
                ToolTip(" `nExtracting update...`n ")
            
            extractDir := updatesDir . "\extracted-" . this.LatestVersion
            if DirExist(extractDir)
                DirDelete(extractDir, true)
            
            psUnzip := 'powershell -NoProfile -WindowStyle Hidden -Command "'
            psUnzip .= 'Add-Type -AssemblyName System.IO.Compression.FileSystem; '
            psUnzip .= '[System.IO.Compression.ZipFile]::ExtractToDirectory(' . ps_str(dlFile) . ', ' . ps_str(extractDir) . ')"'
            
            RunWait(psUnzip, , "Hide")
            
            try FileDelete(dlFile)

            searchExt := A_IsCompiled ? "exe" : "ahk"
            extractedExePath := ""
            
            Loop Files, extractDir . "\*." . searchExt, "R" {
                extractedExePath := A_LoopFileFullPath
                break
            }

            if !silent
                ToolTip()

            if (extractedExePath == "") {
                if !silent
                    MsgBox("Failed to locate an updated ." . searchExt . " file inside the downloaded archive.", "Update Error", 0x40030)
                try DirDelete(extractDir, true)
                return
            }
            
            payloadFile := extractedExePath
        } else {
            payloadFile := dlFile
        }

        Global signalFile := updatesDir . "\ahk_upd_ok.tmp"
        
        newTargetPath := targetFile
        backupFileName := cleanName . "_v" . this.App.Version . "." . targetExt . ".bak"
        Global backupFilePath := targetDir . "\" . backupFileName

        signalArg := signalFile . "|" . backupFilePath . "|" . updatesDir

        ; --- SAFE POWERSHELL EXECUTION WITH HEALTH CHECK ---
        psCmd := 'powershell -NoProfile -WindowStyle Hidden -Command "'
        psCmd .= 'Start-Sleep -Seconds 2; '
        
        ; 1. Rename existing executable to backup
        psCmd .= 'Rename-Item -LiteralPath ' . ps_str(targetFile) . ' -NewName ' . ps_str(backupFileName) . ' -Force; '

        ; 2. Install new binary directly over target path
        psCmd .= 'Copy-Item -LiteralPath ' . ps_str(payloadFile) . ' -Destination ' . ps_str(newTargetPath) . ' -Force; '

        ; 3. Launch new process passing clean arguments with embedded double quotes
        if A_IsCompiled {
            psCmd .= 'if (Test-Path -LiteralPath ' . ps_str(newTargetPath) . ') { Start-Process -FilePath ' . ps_str(newTargetPath) . ' -ArgumentList ' . ps_str('"' . '--signal-update-success=' . signalArg . '"') . ' }; '
        } else {
            psCmd .= 'if (Test-Path -LiteralPath ' . ps_str(newTargetPath) . ') { Start-Process -FilePath ' . ps_str(A_AhkPath) . ' -ArgumentList @(' . ps_str('"' . newTargetPath . '"') . ', ' . ps_str('"' . '--signal-update-success=' . signalArg . '"') . ') }; '
        }

        ; 4. Monitor health check for up to 10 seconds
        psCmd .= '$counter = 0; '
        psCmd .= 'while (-not (Test-Path -LiteralPath ' . ps_str(signalFile) . ') -and $counter -lt 10) { Start-Sleep -Seconds 1; $counter++ }; '
        
        psCmd .= 'if (Test-Path -LiteralPath ' . ps_str(signalFile) . ') { '
        psCmd .= '  Start-Sleep -Milliseconds 500; '
        psCmd .= '  $toDelete = Get-Content -LiteralPath ' . ps_str(signalFile) . ' -ErrorAction SilentlyContinue; '
        psCmd .= '  Remove-Item -LiteralPath ' . ps_str(signalFile) . ' -Force -ErrorAction SilentlyContinue; '
        psCmd .= '  foreach ($item in $toDelete) { '
        psCmd .= '    if ($item -and (Test-Path -LiteralPath $item)) { '
        psCmd .= '      Remove-Item -LiteralPath $item -Recurse -Force -ErrorAction SilentlyContinue '
        psCmd .= '    } '
        psCmd .= '  } '
        psCmd .= '} else { '
        ; Restoration logic if health check fails
        psCmd .= '  Remove-Item -LiteralPath ' . ps_str(newTargetPath) . ' -Force -ErrorAction SilentlyContinue; '
        psCmd .= '  Rename-Item -LiteralPath ' . ps_str(backupFilePath) . ' -NewName ' . ps_str(targetName) . ' -Force -ErrorAction SilentlyContinue; '
        psCmd .= '}"'

        Run(psCmd, , "Hide")
        ExitApp()
    }

    ShowUpdaterGUI(*) {
		static MyGui := ""
		if MyGui
			return WinActivate(MyGui)

        hasUpdate := (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion))

        MyGuiTitle := App.Name . " - Update"
        MyGuiOptions := "+LastFound -MinimizeBox +AlwaysOnTop"
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
        MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
		DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
        offset := 20

        if IsFunctionDefined("CustomTitleBar") {
            MyGui.Opt("-Caption")
            titlebar := %"CustomTitleBar"%.Attach(MyGui, {
                Title: "",
                ShowIcon: false,
                Min: false,
                Max: false,
                Close: true
            })
            offset := 50
        }

		if (UseAcrylicGUI := IsSet(FrostedTheme))
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
                txtBannerTitle.SetFont("s" Settings.GuiFontSizeExtraBig " bold c" TextHoverColor, Settings.GuiFontName)
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

		; GitHub Link
        MyGui.SetFont("s" Settings.GuiFontSizeBig " c" GitNormalColor " w800")
        MyLink := MyGui.Add("Text", "-Tabstop xm y+10", "View Release Notes on GitHub...")
        MyLink.OnEvent("Click", (*) => Run(App.GitHubRepo . "/releases"))
        MyLink.BypassTheme := true


        MyGui.SetFont("s" Settings.GuiFontSizeMedium " Norm w100")
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



		if IsSet(GuiTracker) {
			tracker := GuiTracker()
			tracker.AddGui := MyGui

			tracker.RegisterControl(btnUpdate, Map(
				"OnEnter", (ctrl) => (hasUpdate ? (ctrl.SetFont("c" TextHoverColor), ctrl.Opt("+Background" BGroundHoverColor)) : ""),
				"OnLeave", (ctrl) => (hasUpdate ? (ctrl.SetFont("c" TextNormalColor), ctrl.Opt("+Background" BGroundNormalColor))  : "")
			))

			tracker.RegisterControl(MyLink, Map(
				"OnEnter", (ctrl) => ctrl.SetFont("c" GitHoverColor),
				"OnLeave", (ctrl) => ctrl.SetFont("c" GitNormalColor)
			))
		}

		; Apply Themes
		if UseAcrylicGUI {
			IsSet(ApplyThemeToGui) ? ApplyThemeToGui(MyGui, "Dark") : 0
			IsSet(FrostedTheme) ? FrostedTheme.Apply(MyGui) : 0
		} else {
			IsSet(ApplyThemeToGui) ? ApplyThemeToGui(MyGui) : 0
			IsSet(WatchedGUIs) ? WatchedGUIs.Push(MyGui) : 0
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

        SaveValues(*) {
            this.App.UpdateAuto := (chkAuto.Value != 0)
            this.App.UpdateFrequencyDays := Integer(numFreq.Value)
            App.UpdateAuto := this.App.UpdateAuto
            App.UpdateFrequencyDays := this.App.UpdateFrequencyDays
            App.UpdateLastCheck := this.App.UpdateLastCheck
            ;(Type(SaveINI) == "Func" || Type(SaveINI) == "Closure") ? SaveINI() : ""
			IsSet(SaveINI) ? SaveINI() : 0
        }

        CleanDestroy(*) {
            SaveValues()
            IsSet(RemoveGuiFromArray) ? RemoveGuiFromArray(MyGui) : 0
            MyGui.Destroy()
			MyGui := ""
        }

        IsFunctionDefined(Name) {
            try return HasMethod(%Name%)
            return false
        }
    }
}