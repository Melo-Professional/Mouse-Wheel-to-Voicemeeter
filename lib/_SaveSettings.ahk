/************************************************************************
 * @description Handles user settings utilizing a standard INI file
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/12
 * @version 1.6.0
 ***********************************************************************/

#Requires AutoHotkey v2.0


/*
HOW TO USE

1 - Include this lib
#Include *i <_SaveSettings>

2 - Define what to save to INI format: rootName.path
SaveToINI := ["Settings.DesiredTheme"] ; what to save to INI file
SaveToINI.Push := ["Settings.SplashScreen"] ; add more to INI file
RegisterArrayItems(SaveToINI)

3 - Read the current INI
LoadINI()

4 - Later, to update the INI just run
SaveINI()
*/

class INIManager {
    static IniPath := A_ScriptDir "\" App.NameNoSpace "_UserSettings.ini"
    static Registered := Map()

    static Register(rootName, path) {
        if (!this.Registered.Has(rootName))
            this.Registered[rootName] := []
        this.Registered[rootName].Push(path)
    }

    static RegisterMultiple(rootName, paths*) {
        if (!this.Registered.Has(rootName))
            this.Registered[rootName] := []
        
        for path in paths {
            this.Registered[rootName].Push(path)
        }
    }

    static Load(rootObj, rootName) {
        if (!FileExist(this.IniPath))
            return rootObj

        for path in this.Registered.Get(rootName, []) {
            keyName := StrReplace(path, ".", "_")
            ; Use "NOT_FOUND" placeholder to separate missing keys from intentionally blank values
            value   := IniRead(this.IniPath, rootName, keyName, "NOT_FOUND")

            ; Process the property if it was explicitly found in the INI file
            if (value != "NOT_FOUND") {
                this._SetByPath(rootObj, path, value)
            }
        }
        return rootObj
    }

    static Save(rootObj, rootName) {
        for path in this.Registered.Get(rootName, []) {
            value := this._GetByPath(rootObj, path)
            IniWrite(value, this.IniPath, rootName, StrReplace(path, ".", "_"))
        }
    }

    static LoadAll() {
        for rootName, _ in this.Registered {
            try this.Load(%rootName%, rootName)
        }
    }

    static SaveAll() {
        for rootName, _ in this.Registered {
            try this.Save(%rootName%, rootName)
        }
    }

    static _GetByPath(obj, path) {
        keys := StrSplit(path, ".")
        current := obj
        for key in keys {
            if (!IsObject(current) || !current.HasOwnProp(key))
                return ""
            current := current.%key%
        }
        return current
    }

    static _SetByPath(obj, path, value) {
        keys := StrSplit(path, ".")
        current := obj
        for i, key in keys {
            if (i = keys.Length) {
                ; Check if the property already exists in the default object
                if current.HasOwnProp(key) {
                    originalValue := current.%key%
                    origType := Type(originalValue)

                    if (origType = "Integer") {
                        ; Since Booleans are Integers in AHK v2, check the incoming INI string first
                        if (value = "true" || value = "1") {
                            current.%key% := true
                        } else if (value = "false") {
                            current.%key% := false
                        } else if (value == "") {
                            current.%key% := 0
                        } else if IsNumber(value) {
                            ; Only convert to Integer if the INI value is a valid number
                            current.%key% := Integer(value)
                        } else {
                            ; Dynamic fallback: accept text strings like "Auto"
                            current.%key% := String(value)
                        }
                    }
                    else if (origType = "Float") {
                        if (value == "") {
                            current.%key% := 0.0
                        } else if IsNumber(value) {
                            current.%key% := Float(value)
                        } else {
                            current.%key% := String(value)
                        }
                    }
                    else {
                        ; Keeps strings intact (crucial for empty hotkeys "" or Hex colors)
                        current.%key% := String(value)
                    }
                } else {
                    ; Fallback for undefined properties: save as safe String
                    current.%key% := value
                }
            } else {
                if (!current.HasOwnProp(key) || !IsObject(current.%key%))
                    current.%key% := {}
                current := current.%key%
            }
        }
    }
}

LoadINI(*) {
    INIManager.LoadAll()
}

SaveINI(*) {
    INIManager.SaveAll()
}

RegisterArrayItems(itemArray) {
    for index, fullString in itemArray {
        ; Split the string at the first dot
        ; Limiting to 2 parts ensures keys containing dots remain unbroken
        parts := StrSplit(fullString, ".", , 2)
        
        if (parts.Length == 2) {
            ; parts[1] is the Category, parts[2] is the Key path
            INIManager.Register(parts[1], parts[2])
        }
    }
}