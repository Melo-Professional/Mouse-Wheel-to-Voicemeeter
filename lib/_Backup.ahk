/************************************************************************
 * @description Automatic Backup and Compilation Manager for AHK v2.
 * @author Melo (melo@meloprofessional.com) and Pj
 * @date 2026/07/30
 * @version 1.6.0
 * 
 * FEATURES:
 * - Creates an isolated '.versions\' directory automatically inside A_ScriptDir.
 * 
 * - Handles dual backup modes via global variables:
 *   1. "AppVersionOnly": Backs up exactly once per version string change.
 *   2. "AppVersionAndMinutes": Backs up on version change OR if the newest 
 *      backup is older than a specified minute threshold.
 * 
 * - Filters clutter: Skips hidden/system elements, workspace configurations, 
 *   operating system inner files (desktop.ini/thumbs.db), and the active executable.
 * 
 * - Selective Dependency Mapping: Parses the script for `#Include` statements, 
 *   copying only the active target files inside the `lib\` folder.
 * 
 * - Template Master Switch: Forces a complete, un-filtered copy of the `lib\` 
 *   folder if the running script name matches the `templateName` variable.
 * 
 * - Compiler Automation: Bypasses all version/time limits if `comp.exe` is found 
 *   in A_ScriptDir. Moves and renames `comp.exe` to `%scriptname%.exe` inside a 
 *   `\compilation\` subfolder, then appends the customized ` - COMPILED` string.
 *   If there are content in an 'assets' folder, it will zip the \compilation\` 
 *   subfolder with the assets.
 * 
 * - Zip Compression: Optional `compressBackup` flag that automatically compresses 
 *   the final backup folder into a standard ZIP archive and removes the uncompressed folder.
 * 
 * HOW TO USE:
 * 1. Define required parameters in your script's main header:
 *    global AppVersion := "1.0.0"
 *    global compressBackup := true
 * 
 * 2. #Include this library in your main script after global AppVersion is defined
  ***********************************************************************/

;global AppVersion       := "1.0.1"

Backup()
Backup() {
    if A_IsCompiled
        return

    Global _bkpMode, _bkpMinutesThreshold, _bkpSeparator, _bkpTemplateName, AppVersion, _bkpArchive, _bkpTimeFormat

	AppVersion				:= IsSet(AppVersion)				? AppVersion				: "0.0.0.0"              ; AppVersion
	_bkpMode				:= IsSet(_bkpMode)					? _bkpMode					: "AppVersionOnly"       ; Options: "AppVersionOnly" or "AppVersionAndMinutes"
	_bkpMinutesThreshold	:= IsSet(_bkpMinutesThreshold)		? _bkpMinutesThreshold		: 30                     ; Minutes to check if backupMode is time-based
	_bkpTemplateName		:= IsSet(_bkpTemplateName)			? _bkpTemplateName 			: "Template"             ; Script name that triggers full lib folder copy
	_bkpSeparator			:= IsSet(_bkpSeparator)				? _bkpSeparator				: "-"                    ; Separator character for folder names
	_bkpTimeFormat			:= IsSet(_bkpTimeFormat)			? _bkpTimeFormat 			: "yyyy.MM.dd_HH.mm.ss"  ; Time format
	_bkpArchive				:= IsSet(_bkpArchive)				? _bkpArchive				: false                  ; Toggles zipping backup

    versionsDir := A_ScriptDir "\.versions"
    if !DirExist(versionsDir)
        DirCreate(versionsDir)

    SplitPath(A_ScriptFullPath, &fullFileName,,, &scriptname)
    
    ; Determine if comp.exe forces an absolute backup bypass
    hasCompExe := FileExist(A_ScriptDir "\comp.exe")

    ; -------------------------------------------------------------------
    ; 0. Version and Time Condition Checks (Ignored if comp.exe exists)
    ; -------------------------------------------------------------------
    if (!hasCompExe) {
        hasExistingBackup := false
        newestTimestamp := ""

        Loop Files, versionsDir "\*", "FD" {
            if (InStr(A_LoopFileName, AppVersion) = 1) {
                hasExistingBackup := true
                
                ; Extract everything after the AppVersion and separator
                rawTime := SubStr(A_LoopFileName, StrLen(AppVersion) + StrLen(_bkpSeparator) + 1)
                
                ; Strip everything except pure digits (removes dots, spaces, underscores, and text)
                cleanTime := RegExReplace(rawTime, "\D")
                
                ; Safe-check that we have a valid timestamp length before running DateDiff
                if (StrLen(cleanTime) >= 14) {
                    cleanTime := SubStr(cleanTime, 1, 14)
                    if (newestTimestamp = "" || DateDiff(cleanTime, newestTimestamp, "Seconds") > 0) {
                        newestTimestamp := cleanTime
                    }
                }
            }
        }

        if (hasExistingBackup) {
            if (_bkpMode = "AppVersionOnly") {
                return ; Skip backup
            }
            else if (_bkpMode = "AppVersionAndMinutes" && newestTimestamp != "") {
                timeDiffMinutes := DateDiff(A_Now, newestTimestamp, "Minutes")
                if (timeDiffMinutes < _bkpMinutesThreshold) {
                    return ; Not old enough yet, skip backup
                }
            }
        }
    }

    ToolTip("`n`n"
        "          Backup starting          `n"
        "          " scriptname " - " AppVersion "          `n`n"
        " ",,,20)

    ; -------------------------------------------------------------------
    ; Setup target paths
    ; -------------------------------------------------------------------
    timestamp := FormatTime(A_Now, _bkpTimeFormat)
    targetDir := versionsDir "\" AppVersion _bkpSeparator timestamp
    DirCreate(targetDir)

    ; -------------------------------------------------------------------
    ; 1. Copy Files with Recursive Filters (Exceptions handled)
    ; -------------------------------------------------------------------
    Loop Files, A_ScriptDir "\*", "R" {
        relPath := SubStr(A_LoopFileFullPath, StrLen(A_ScriptDir) + 2)
        
        ; Skip hidden files, system files, or specific dot-folders like .versions itself
        if (InStr(A_LoopFileAttrib, "H") || InStr(A_LoopFileAttrib, "S"))
            continue
        if (InStr(relPath, ".versions\") = 1 || relPath = ".versions")
            continue

        ; Parse elements split by path separator to check for hidden dot-folders/files
        isDotItem := false
        Loop Parse, relPath, "\" {
            if (SubStr(A_LoopField, 1, 1) = ".") {
                isDotItem := true
                break
            }
        }
        if (isDotItem)
            continue

        ; Workspace, OS specific files, current executable, and comp.exe exclusions
        if (A_LoopFileExt = "code-workspace" 
            || A_LoopFileName = "desktop.ini" 
            || A_LoopFileName = "thumbs.db" 
            || A_LoopFileName = scriptname ".exe"
            || A_LoopFileName = "comp.exe"
            || InStr(relPath, "lib\") = 1) {
            continue
        }

        ; Replicate folder architecture and copy matching items
        SplitPath(targetDir "\" relPath, , &outDir)
        if !DirExist(outDir)
            DirCreate(outDir)
            
        FileCopy(A_LoopFileFullPath, targetDir "\" relPath, 1)
    }

    ; -------------------------------------------------------------------
    ; 2. Specialized Lib Copying Logic
    ; -------------------------------------------------------------------
    if DirExist(A_ScriptDir "\lib") {
        DirCreate(targetDir "\lib")

        if (scriptname = _bkpTemplateName) {
            DirCopy(A_ScriptDir "\lib", targetDir "\lib", 1)
        } 
        else {
            scriptContent := FileRead(A_ScriptFullPath)
            
            Loop Parse, scriptContent, "`n", "`r" {
                if RegExMatch(A_LoopField, "i)^\s*#Include\s+(?:\*i\s+)?<?([^>\s]+)>?", &match) {
                    includePath := match[1]
                    
                    ; Append .ahk extension if omitted
                    if !(includePath ~= "\.[a-zA-Z0-9]+$") {
                        includePath .= ".ahk"
                    }
                    
                    ; Strip lead "lib\" or "lib/" if explicitly declared in the #Include
                    relLibPath := RegExReplace(includePath, "i)^lib[/\\]", "")
                    
                    ; Resolve full path inside source lib folder
                    sourceFile := A_ScriptDir "\lib\" relLibPath
                    
                    if FileExist(sourceFile) {
                        destFile := targetDir "\lib\" relLibPath
                        
                        ; Ensure subfolders exist inside destination before copying
                        SplitPath(destFile, , &destDir)
                        if !DirExist(destDir)
                            DirCreate(destDir)
                            
                        FileCopy(sourceFile, destFile, 1)
                    }
                }
            }
        }
    }

; -------------------------------------------------------------------
    ; 3. Handle compilation movement, assets, & zipping
    ; -------------------------------------------------------------------
    if (hasCompExe) {
        assetsSrc := A_ScriptDir "\assets"
        hasAssets := DirExist(assetsSrc)
        
        hasAssetsContent := false
        if (hasAssets) {
            Loop Files, assetsSrc "\*", "FD" {
                hasAssetsContent := true
                break
            }
        }

        if (!hasAssets || !hasAssetsContent) {
            ; Case 1: No assets or empty assets folder
            compDir := targetDir "\compilation"
            if !DirExist(compDir)
                DirCreate(compDir)

            FileMove(A_ScriptDir "\comp.exe", compDir "\" scriptname ".exe", 1)

        } else {
            ; Case 2: Assets folder exists and has content
            scriptCompDir := targetDir "\compilation\" scriptname
            if !DirExist(scriptCompDir)
                DirCreate(scriptCompDir)

            ; Move comp.exe and copy assets
            FileMove(A_ScriptDir "\comp.exe", scriptCompDir "\" scriptname ".exe", 1)
            DirCopy(assetsSrc, scriptCompDir "\assets", 1)

            ; Zip compilation\%scriptname%\ folder in place
            zipPath := targetDir "\compilation\" scriptname ".zip"
            RunWait('powershell -NoProfile -NonInteractive -Command "Compress-Archive -Path \"' scriptCompDir '\*\" -DestinationPath \"' zipPath '\" -Force"', , "Hide")
        }

        ; Append COMPILED tag to final backup folder name
        compiledTargetDir := targetDir _bkpSeparator "COMPILED"
        DirMove(targetDir, compiledTargetDir, 1)
        targetDir := compiledTargetDir
    }

    ; -------------------------------------------------------------------
    ; 4. Optional Backup Compression (For standard non-compilation backups)
    ; -------------------------------------------------------------------
    if (_bkpArchive && !hasCompExe) {
        zipPath := targetDir ".zip"
        
        RunWait('powershell -NoProfile -NonInteractive -Command "Compress-Archive -Path \"' targetDir '\*\" -DestinationPath \"' zipPath '\" -Force"', , "Hide")
        
        if FileExist(zipPath) {
            DirDelete(targetDir, 1)
        }
    }
    
    ToolTip("`n`n"
        "          Backup created          `n"
        "          " scriptname " - " AppVersion "          `n`n"
        " ",,,20)
    SetTimer(() => ToolTip(,,,20), -7000)
}