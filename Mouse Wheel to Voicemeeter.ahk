; Mouse Wheel to Voicemeeter
; version 1.3
; by Melo (melo@meloprofessional.com)
; 
; Credits to:
; VMR AHK https://github.com/SaifAqqad/VMR.ahk
; trismarck code from here: https://www.autohotkey.com/board/topic/96139-detect-screen-edges-two-monitors/
 



MacroButtonMuteUnmuteVirtualInput:=[]
; CUSTOMIZATION START
; Your macro button ID for mute / unmute 1st virtual input, if any
MacroButtonMuteUnmuteVirtualInput[1] :=

; Your macro button ID for mute / unmute 2nd virtual input, if any
MacroButtonMuteUnmuteVirtualInput[2] :=

; Your macro button ID for mute / unmute 3rd virtual input, if any
MacroButtonMuteUnmuteVirtualInput[3] :=

; Slow steps for changing volume
gainsteps1 := 3

; Fast steps for changing volume
gainsteps2 := 12
; CUSTOMIZATION END 
 



SetWorkingDir %A_ScriptDir%
#SingleInstance Force
#MaxThreadsPerHotkey 200
;OPTIMIZATIONS START
#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
;OPTIMIZATIONS END

Appname := "Mouse Wheel to Voicemeeter"
Version := 1.3
;stripnum := stripdesktop
directionup := false
gainsteps := gainsteps1
global x
global Appname
global Version
global voicemeeter

Coordmode, Mouse, Screen
SM_CMONITORS := 80
SysGet, monCount, % SM_CMONITORS
Loop, % monCount
	SysGet, mon%A_Index%, Monitor, %A_Index%
Menu, Tray, Icon, %A_ScriptDir%\mwvm.ico
Menu, Tray, Tip , WAITING VOICEMEETER...
Menu, Tray, NoStandard
Menu, Tray, deleteall
Menu, Tray, Add, Waiting for Voicemeeter start, opener	
Menu, Tray, Default, 1&
Menu, Tray, Click, 1
Menu, Tray, Rename, 1&
Menu, Tray, Add, --- Waiting Voicemeeter --- , opener
Menu, Tray, Disable, --- Waiting Voicemeeter ---
Menu, Tray, Add, Voicemeeter , Voice_Meeter
Menu, Tray, Disable, Voicemeeter
Menu, Tray, Add, Restart Audio Engine , Voice_Meeter_Restart
Menu, Tray, Disable, Restart Audio Engine
Menu, Tray, Add, Macro Buttons , Macro_Buttons
Menu, Tray, Disable, Macro Buttons
Menu, Tray, Add
Menu, Tray, Add, Control Panel Sounds , Sounds
Menu, Tray, Add, Windows Volume Mixer , Volume_Mixer
Menu, Tray, Add
Menu, Tray, Add, Start on Boot, BootMenu
If (CheckStartOnBoot())
	Menu, Tray, Check, Start on Boot
else
	Menu, Tray, Uncheck, Start on Boot
Menu, Tray, Add, Restart , Restart
Menu, Tray, Add, About, About
Menu, Tray, Add, Exit, Exit
Menu, Tray, Click, 1

Loop
{
	try
	{
		#Include %A_ScriptDir%\VMR.ahk
		break
	}
	catch
		sleep 1000
}

Menu, Tray, Tip , %Appname%
Menu, Tray, Delete, --- Waiting Voicemeeter ---
Menu, Tray, Enable, Voicemeeter
Menu, Tray, Enable, Restart Audio Engine
Menu, Tray, Enable, Macro Buttons

voicemeeter := new VMR().login()
vm_type := voicemeeter.getType()
;vm_type := 3

Fader := []
Switch vm_type {
    case 1:
        Fader[1]:= 3
        Fader[2]:=
        Fader[3]:=
    case 2:
        Fader[1]:= 4
        Fader[2]:= 5
        Fader[3]:=
    case 3:
        Fader[1]:= 6
        Fader[2]:= 7
        Fader[3]:= 8
}
Total_Faders := Fader.MaxIndex()
Return

opener:
Menu, Tray, Show
return

CheckStartOnBoot(){
RegRead, StartupReg, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, %Appname%
return StartupReg
}

Sounds:
runwait control mmsys.cpl sounds
Return

Volume_Mixer:
runwait sndvol.exe
Return

Voice_Meeter:
voicemeeter.command.show(1)
return

Voice_Meeter_Restart:
voicemeeter.command.restart()
return

Macro_Buttons:
voicemeeter.macroButton.show(1)
return

BootMenu:
If (CheckStartOnBoot()){
	RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, %Appname%
	Menu, Tray, Uncheck, Start on Boot
}else{
	RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, %Appname%, %A_AhkPath%
	Menu, Tray, Check, Start on Boot
}
Return

Restart:
Reload
Return

About:
MsgBox ,,%Appname%,Mouse Wheel to Voicemeeter`nversion %Version%`n`nTo control Voicemeeter virtual inputs volumes from mouse wheel over Taskbar.`n`n`n`nBy Melo`nmelo@meloprofessional.com`n© Melo. All rights reserved.
return

Exit:
ExitApp
Return

#if MouseIsOver("ahk_class Shell_TrayWnd") || MouseIsOver("ahk_class Shell_SecondaryTrayWnd")

WheelUp::
directionup := true
WheelDown::
If (A_PriorHotKey = A_ThisHotKey and A_TimeSincePriorHotkey < 50)
	gainsteps := gainsteps2
else{
	Loop, % monCount {
		i := A_Index
		if ( x >= mon%i%Left ) && ( x <= mon%i%Right )
			break
	}
}
total_width := mon%i%Right - mon%i%Left
width := total_width / Total_Faders
Loop, % Total_Faders {
	portion := A_Index
	width_start := mon%i%Left + ((width * portion ) - width)
	width_end := width_start + width
	if ( x >= width_start ) && ( x <= width_end )
		break
}

stripnum := Fader[portion]

if ( directionup ){
	if(voicemeeter.macroButton.getStatus(MacroButtonMuteUnmuteVirtualInput[portion]))
		voicemeeter.macroButton.setStatus(MacroButtonMuteUnmuteVirtualInput[portion],1,0)
	voicemeeter.strip[stripnum].mute := 0
	voicemeeter.strip[stripnum].gain+=gainsteps
}
else
	voicemeeter.strip[stripnum].gain-=gainsteps

gainsteps := gainsteps1
directionup := false
return
#If

MouseIsOver(WinTitle)
{
MouseGetPos, x, , Win
Return WinExist(WinTitle . " ahk_id " . Win), x
}