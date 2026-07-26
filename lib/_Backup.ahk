/************************************************************************
 * @description Automatic Backup and Compilation Manager for AHK v2.
 * @author Melo (melo@meloprofessional.com) and Pj
 * @date 2026/07/24
 * @version 1.1.5
 * 
 * FEATURES:
 * - Creates a isolated '.versions\' directory automatically inside A_ScriptDir.
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
 * 
 * HOW TO USE:
 * 1. Define this required parameters in your script's main header:
 *    global AppVersion       := "1.0.0"
 * 
 * 2. #Include this library in your main script after global AppVersion is defined
  ***********************************************************************/

;global AppVersion       := "1.0.1"

Backup()
Backup() {
    if A_IsCompiled
        return

    Global backupMode, backupMinutesThreshold, backupSeparator, backupTemplateName

    if !IsSet(backupMode)
        backupMode                      := "AppVersionOnly" ; Options: "AppVersionOnly" or "AppVersionAndMinutes"

    if !IsSet(backupMinutesThreshold)
        backupMinutesThreshold          := 30                     ; Minutes to check if backupMode is time-based

    if !IsSet(backupSeparator)
        backupSeparator                 := "-"                    ; Separator character for folder names

    if !IsSet(backupTemplateName)
        backupTemplateName              := "Template"             ; Script name that triggers full lib folder copy

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

        Loop Files, versionsDir "\*", "D" {
            if (InStr(A_LoopFileName, AppVersion) = 1) {
                hasExistingBackup := true
                
                ; Extract everything after the AppVersion and separator
                rawTime := SubStr(A_LoopFileName, StrLen(AppVersion) + StrLen(backupSeparator) + 1)
                
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
            if (backupMode = "AppVersionOnly") {
                return ; Skip backup
            }
            else if (backupMode = "AppVersionAndMinutes" && newestTimestamp != "") {
                timeDiffMinutes := DateDiff(A_Now, newestTimestamp, "Minutes")
                if (timeDiffMinutes < backupMinutesThreshold) {
                    return ; Not old enough yet, skip backup
                }
            }
        }
    }

    ; -------------------------------------------------------------------
    ; Setup target paths
    ; -------------------------------------------------------------------
    timestamp := FormatTime(A_Now, "yyyy.MM.dd_HH.mm.ss")
    targetDir := versionsDir "\" AppVersion backupSeparator timestamp
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

        if (scriptname = backupTemplateName) {
            DirCopy(A_ScriptDir "\lib", targetDir "\lib", 1)
        } 
        else {
            scriptContent := FileRead(A_ScriptFullPath)
            
            Loop Parse, scriptContent, "`n", "`r" {
                if RegExMatch(A_LoopField, "i)^\s*#Include\s+(?:\*i\s+)?<?([^>\s]+)>?", &match) {
                    includePath := match[1]
                    
                    if !(includePath ~= "\.[a-zA-Z0-9]+$") {
                        includePath .= ".ahk"
                    }
                    
                    SplitPath(includePath, &libFileName)
                    sourceFile := A_ScriptDir "\lib\" libFileName
                    
                    if FileExist(sourceFile) {
                        FileCopy(sourceFile, targetDir "\lib\" libFileName, 1)
                    }
                }
            }
        }
    }

    ; -------------------------------------------------------------------
    ; 1.1. Handle compilation movement & final folder naming flags
    ; -------------------------------------------------------------------
    if (hasCompExe) {
        compDir := targetDir "\compilation"
        if !DirExist(compDir)
            DirCreate(compDir)
        
        FileMove(A_ScriptDir "\comp.exe", compDir "\" scriptname ".exe", 1)
        DirMove(targetDir, targetDir backupSeparator "COMPILED", 1)
    }
    ToolTip("`n`n          Backup created          `n`n ",,,20)
    SetTimer(() => ToolTip(,,,20), -7000)
}