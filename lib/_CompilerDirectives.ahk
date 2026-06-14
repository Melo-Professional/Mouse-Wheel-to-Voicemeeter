/************************************************************************
 * @description Compiler Directives
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/07
 * @version 1.3.0
 ***********************************************************************/

;@region Compilation
;@Ahk2Exe-Let U_appname = %U_AppName~U)^.*?AppName\s*:=\s*"([^"]+)".*$~$1%
;@Ahk2Exe-Let U_version = %U_Version~U)^.*?AppVersion\s*:=\s*"([^"]+)".*$~$1%
;@Ahk2Exe-Let U_appnameclean = %U_appname~\s+%
;@Ahk2Exe-SetName %U_appname%
;@Ahk2Exe-SetProductName %U_appname%
;@Ahk2Exe-SetInternalName %U_appname%
;@Ahk2Exe-SetDescription %U_appname%
;@Ahk2Exe-SetVersion %U_version%
;@Ahk2Exe-SetCompanyName Melo Professional
;@Ahk2Exe-SetCopyright © Melo. All rights reserved.
;@Ahk2Exe-SetMainIcon .\lib\app.ico
;@Ahk2Exe-AddResource .\lib\app.ico, 160
;@Ahk2Exe-AddResource .\lib\app.ico, 206
;@Ahk2Exe-AddResource .\lib\app_Pause.ico, 207
;@Ahk2Exe-AddResource .\lib\app.ico, 208
;@Ahk2Exe-ExeName %U_appnameclean%
;@Ahk2Exe-UpdateManifest 0, %U_appname%

;@Ahk2Exe-IgnoreBegin

/* PUT THIS IN THE BEGINNING OF THE AHK SCRIPT:

AppName := "Template"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "2.8.10.0"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "This is a template as a starting point for your AutoHotKey projects."
;@endregion

#Include *i <_CompilerDirectives>
*/

; lost and found bellow
;@Ahk2Exe-Let U_appname = %AppName%
;@Ahk2Exe-Let U_version = %AppVersion%
;@Ahk2Exe-Let U_appnameclean = %U_appname~\s+%
;@Ahk2Exe-SetName %U_appname%
;@Ahk2Exe-SetProductName %U_appname%
;@Ahk2Exe-SetInternalName %U_appname%
;@Ahk2Exe-SetDescription %U_appname%
;@Ahk2Exe-SetVersion %U_version%
;@Ahk2Exe-SetCompanyName Melo Professional
;@Ahk2Exe-SetCopyright © Melo. All rights reserved.
;@Ahk2Exe-ExeName %U_appnameclean%
;@Ahk2Exe-SetMainIcon .\lib\app.ico
;@Ahk2Exe-AddResource .\lib\app.ico, 160
;@Ahk2Exe-AddResource .\lib\app.ico, 206
;@Ahk2Exe-AddResource .\lib\app_Pause.ico, 207
;@Ahk2Exe-AddResource .\lib\app.ico, 208
;@Ahk2Exe-UpdateManifest 0, %U_appname%

;@Ahk2Exe-Let U_appname = %U_LineAppName~U)^.*?AppName\s*:=\s*"([^"]+)".*$~$1%
;@Ahk2Exe-Let U_version = %U_LineVersion~U)^.*?AppVersion\s*:=\s*"([^"]+)".*$~$1%
;@Ahk2Exe-SetMainIcon .\lib\%U_appnameclean%.ico
;@Ahk2Exe-AddResource .\lib\%U_appnameclean%.ico, 160
;@Ahk2Exe-AddResource .\lib\%U_appnameclean%.ico, 206
;@Ahk2Exe-AddResource .\lib\%U_appnameclean%_Pause.ico, 207
;@Ahk2Exe-AddResource .\lib\%U_appnameclean%.ico, 208
;@Ahk2Exe-IgnoreEnd
;@endregion