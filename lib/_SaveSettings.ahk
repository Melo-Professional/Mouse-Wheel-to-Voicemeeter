/************************************************************************
 * @description Handles user settings utilizing a standard INI file
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.5.0
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
            value   := IniRead(this.IniPath, rootName, keyName, "")

            if (value != "") {
                this._SetByPath(rootObj, path, value)
            }
        }
        return rootObj
    }

    static Save(rootObj, rootName) {
        for path in this.Registered.Get(rootName, []) {
            value := this._GetByPath(rootObj, path)
            if (value != "")
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
                ; 1. Check if the property already exists in the default object
                if current.HasOwnProp(key) {
                    originalValue := current.%key%
                    origType := Type(originalValue)

                    ; 2. Enforce strict type matching based on the original script definition
                    if (originalValue = true || originalValue = false) {
                        ; Convert "1"/"true" strings back to proper booleans
                        current.%key% := (value = "1" || value = "true")
                    }
                    else if (origType = "Integer") {
                        current.%key% := Integer(value)
                    }
                    else if (origType = "Float") {
                        current.%key% := Float(value)
                    }
                    else {
                        ; Keeps strings intact (crucial for Hex colors like "272525")
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