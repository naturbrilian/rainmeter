!verbose 3
!addplugindir ".\"
!ifndef VER
 !define VER "0.0"
 !define REV "000"
!else
 !define INCLUDEFILES
!endif
!ifdef BETA
 !define OUTFILE "Rainmeter-${VER}-r${REV}-beta.exe"
!else
 !define OUTFILE "Rainmeter-${VER}.exe"
!endif

Name "Rainmeter"
VIAddVersionKey "ProductName" "Rainmeter"
VIAddVersionKey "FileDescription" "Rainmeter Installer"
VIAddVersionKey "FileVersion" "${VER}.0"
VIAddVersionKey "ProductVersion" "${VER}.0.${REV}"
VIAddVersionKey "OriginalFilename" "${OUTFILE}"
VIAddVersionKey "LegalCopyright" "Copyright (C) 2009-2012 - All authors"
VIProductVersion "${VER}.0.${REV}"
BrandingText " "
SetCompressor /SOLID lzma
RequestExecutionLevel user
InstallDirRegKey HKLM "SOFTWARE\Rainmeter" ""
ShowInstDetails nevershow
XPStyle on
OutFile "..\${OUTFILE}"
ReserveFile "${NSISDIR}\Plugins\LangDLL.dll"
ReserveFile "${NSISDIR}\Plugins\nsDialogs.dll"
ReserveFile "${NSISDIR}\Plugins\System.dll"
ReserveFile ".\UAC.dll"

!include "MUI2.nsh"
!include "x64.nsh"
!include "FileFunc.nsh"
!include "WordFunc.nsh"
!include "WinVer.nsh"
!include "UAC.nsh"

; Additional Windows definitions
!define BCM_SETSHIELD 0x0000160c
!define PF_XMMI_INSTRUCTIONS_AVAILABLE 6
!define PF_XMMI64_INSTRUCTIONS_AVAILABLE 10

!define MUI_HEADERIMAGE
!define MUI_ICON ".\Icon.ico"
!define MUI_UNICON ".\Icon.ico"
!define MUI_HEADERIMAGE_BITMAP ".\Header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP ".\Header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP ".\Wizard.bmp"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION FinishRun
!define MUI_WELCOMEPAGE ; For language strings

Page custom PageWelcome PageWelcomeOnLeave
Page custom PageOptions PageOptionsOnLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

UninstPage custom un.PageOptions un.GetOptions
!insertmacro MUI_UNPAGE_INSTFILES

; Include languages
!macro IncludeLanguage LANGUAGE CUSTOMLANGUAGE
	!insertmacro MUI_LANGUAGE ${LANGUAGE}
	!insertmacro LANGFILE_INCLUDE "..\..\Language\${CUSTOMLANGUAGE}.nsh"
!macroend
!define IncludeLanguage "!insertmacro IncludeLanguage"
!include "Languages.nsh"

; Error levels (for silent install)
!define ERROR_UNSUPPORTED	3
!define ERROR_NOTADMIN		4
!define ERROR_WRITEFAIL		5
!define ERROR_NOVCREDIST	6
!define ERROR_CLOSEFAIL		7

Var NonDefaultLanguage
Var AutoStartup
Var Install64Bit
Var InstallPortable
Var un.DeleteAll

; Install
; --------------------------------------
Function .onInit
	${If} ${RunningX64}
		${EnableX64FSRedirection}
	${EndIf}

	${IfNot} ${UAC_IsInnerInstance}
		${If} ${IsWin2000}
			${If} ${Silent}
				SetErrorLevel ${ERROR_UNSUPPORTED}
			${Else}
				MessageBox MB_OK|MB_ICONINFORMATION "$(WIN2KERROR)"
			${EndIf}
			Quit
		${ElseIf} ${IsWinXP}
		${AndIf} ${AtMostServicePack} 1
			${If} ${Silent}
				SetErrorLevel ${ERROR_UNSUPPORTED}
			${Else}
				MessageBox MB_OK|MB_ICONINFORMATION "$(WINXPS2ERROR)"
			${EndIf}
			Quit
		${ElseIf} ${IsWin2003}
		${AndIf} ${AtMostServicePack} 0
			${If} ${Silent}
				SetErrorLevel ${ERROR_UNSUPPORTED}
			${Else}
				MessageBox MB_OK|MB_ICONINFORMATION "$(WIN2003SP1ERROR)"
			${EndIf}
			Quit
		${EndIf}

		ReadRegStr $0 HKLM "SOFTWARE\Rainmeter" "Language"
		ReadRegDWORD $NonDefaultLanguage HKLM "SOFTWARE\Rainmeter" "NonDefault"

		${IfNot} ${Silent}
			${If} $0 == ""
			${OrIf} $0 != $LANGUAGE
			${AndIf} $NonDefaultLanguage != 1
				; New install or better match
				LangDLL::LangDialog "$(^SetupCaption)" "Please select the installer language.$\n$(SELECTLANGUAGE)" AC ${LANGUAGES} ""
				Pop $0
				${If} $0 == "cancel"
					Abort
				${EndIf}

				${If} $0 != $LANGUAGE
					; User selected non-default language
					StrCpy $NonDefaultLanguage 1
				${EndIf}
			${EndIf}

			StrCpy $LANGUAGE $0
		${Else}
			${If} $0 != ""
				StrCpy $LANGUAGE $0
			${EndIf}

			${GetParameters} $R1

			ClearErrors
			${GetOptions} $R1 "/LANGUAGE=" $0
			${IfNot} ${Errors}
				${If} $LANGUAGE != $0
					StrCpy $NonDefaultLanguage 1
				${EndIf}

				StrCpy $LANGUAGE $0
			${EndIf}

			${GetOptions} $R1 "/STARTUP=" $0
			${If} $0 = 1
				StrCpy $AutoStartup 1
			${EndIf}

			${GetOptions} $R1 "/PORTABLE=" $0
			${If} $0 = 1
				StrCpy $InstallPortable 1
			${Else}
				${IfNot} ${UAC_IsAdmin}
					SetErrorLevel ${ERROR_NOTADMIN}
					Quit
				${EndIf}
			${EndIf}

			${GetOptions} $R1 "/VERSION=" $0
			${If} $0 = 64
				StrCpy $Install64Bit 1

				${If} $INSTDIR == ""
					StrCpy $INSTDIR "$PROGRAMFILES64\Rainmeter"
				${EndIf}
			${Else}
				${If} $INSTDIR == ""
					StrCpy $INSTDIR "$PROGRAMFILES\Rainmeter"
				${EndIf}
			${EndIf}

			ClearErrors
			CreateDirectory "$INSTDIR"
			WriteINIStr "$INSTDIR\_rainmeter_writetest.tmp" "1" "1" "1"
			Delete "$INSTDIR\_rainmeter_writetest.tmp"

			${If} ${Errors}
				SetErrorLevel ${ERROR_WRITEFAIL}
				Quit
			${EndIf}
		${EndIf}
	${Else}
		; Exchange settings with user instance
		!insertmacro UAC_AsUser_Call Function ExchangeSettings ${UAC_SYNCREGISTERS}
		StrCpy $AutoStartup $1
		StrCpy $Install64Bit $2
		StrCpy $NonDefaultLanguage $3
		StrCpy $LANGUAGE $4
	${EndIf}
FunctionEnd

Function ExchangeSettings
	StrCpy $1 $AutoStartup
	StrCpy $2 $Install64Bit
	StrCpy $3 $NonDefaultLanguage
	StrCpy $4 $LANGUAGE
	HideWindow
FunctionEnd

Function PageWelcome
	${If} ${UAC_IsInnerInstance}
		${If} ${UAC_IsAdmin}
			; Skip page
			Abort
		${Else}
			MessageBox MB_OK|MB_ICONSTOP "$(ADMINERROR) (Inner)"
			Quit
		${EndIf}
	${EndIf}

	!insertmacro MUI_HEADER_TEXT "$(INSTALLOPTIONS)" "$(^ComponentsSubText1)"
	nsDialogs::Create 1044
	Pop $0
	nsDialogs::SetRTL $(^RTL)
	SetCtlColors $0 "" "${MUI_BGCOLOR}"

	${NSD_CreateBitmap} 0u 0u 109u 193u ""
	Pop $0
	${NSD_SetImage} $0 $PLUGINSDIR\modern-wizard.bmp $R0

	${NSD_CreateLabel} 120u 10u 195u 38u "$(MUI_TEXT_WELCOME_INFO_TITLE)"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"
	CreateFont $1 "$(^Font)" "12" "700"
	SendMessage $0 ${WM_SETFONT} $1 0

	${NSD_CreateLabel} 120u 55u 195u 12u "$(^ComponentsSubText1)"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"

	${NSD_CreateRadioButton} 120u 70u 205u 12u "$(STANDARDINST)"
	Pop $R1
	SetCtlColors $R1 "" "${MUI_BGCOLOR}"
	${NSD_AddStyle} $R1 ${WS_GROUP}
	SendMessage $R1 ${WM_SETFONT} $mui.Header.Text.Font 0

	${NSD_CreateLabel} 132u 82u 185u 24u "$(STANDARDINSTDESC)"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"

	${NSD_CreateRadioButton} 120u 106u 310u 12u "$(PORTABLEINST)"
	Pop $R2
	SetCtlColors $R2 "" "${MUI_BGCOLOR}"
	${NSD_AddStyle} $R2 ${WS_TABSTOP}
	SendMessage $R2 ${WM_SETFONT} $mui.Header.Text.Font 0

	${NSD_CreateLabel} 132u 118u 185u 52u "$(PORTABLEINSTDESC)"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"

	${If} $InstallPortable == 1
		${NSD_Check} $R2
	${Else}
		${NSD_Check} $R1
	${EndIf}

	Call muiPageLoadFullWindow

	nsDialogs::Show
	${NSD_FreeImage} $R0
FunctionEnd

Function PageWelcomeOnLeave
	${NSD_GetState} $R2 $InstallPortable
	Call muiPageUnloadFullWindow
FunctionEnd

Function PageOptions
	${If} ${UAC_IsInnerInstance}
	${AndIf} ${UAC_IsAdmin}
		; Skip page
		Abort
	${EndIf}

	!insertmacro MUI_HEADER_TEXT "$(INSTALLOPTIONS)" "$(INSTALLOPTIONSDESC)"
	nsDialogs::Create 1018
	nsDialogs::SetRTL $(^RTL)

	${NSD_CreateGroupBox} 0 0u -1u 36u "$(^DirSubText)"

	${NSD_CreateDirRequest} 6u 14u 232u 14u ""
	Pop $R0
	SendMessage $R0 ${EM_SETREADONLY} 1 0
	${NSD_OnChange} $R0 PageOptionsDirectoryOnChange

	${NSD_CreateBrowseButton} 242u 14u 50u 14u "$(^BrowseBtn)"
	Pop $R1
	${NSD_OnClick} $R1 PageOptionsBrowseOnClick

	; Set default directory
	${If} $InstallPortable == 1
		${GetRoot} "$WINDIR" $0
		${NSD_SetText} $R0 "$0\Rainmeter"
	${ElseIf} $INSTDIR != ""
		; Disable Browse button if already installed
		EnableWindow $R1 0
		${NSD_SetText} $R0 "$INSTDIR"
	${Else}
		; Fresh install
		${If} ${RunningX64}
			${NSD_SetText} $R0 "$PROGRAMFILES64\Rainmeter"
			${NSD_Check} $R2
		${Else}
			${NSD_SetText} $R0 "$PROGRAMFILES\Rainmeter"
		${EndIf}
	${EndIf}

	StrCpy $1 0

	${If} ${RunningX64}
	${AndIf} $InstallPortable == 1
	${OrIf} $INSTDIR == ""
		${NSD_CreateCheckBox} 6u 54u 285u 12u "$(INSTALL64BIT)"
		Pop $R2
		StrCpy $1 30u
	${Else}
		StrCpy $R2 0
	${EndIf}

	${If} $InstallPortable != 1
		${If} $1 == 0
			StrCpy $0 54u
			StrCpy $1 30u
		${Else}
			StrCpy $0 66u
			StrCpy $1 42u
		${EndIf}

		${NSD_CreateCheckbox} 6u $0 285u 12u "$(AUTOSTARTUP)"
		Pop $R3

		${If} $INSTDIR == ""
			${NSD_Check} $R3
		${Else}
			SetShellVarContext all
			${If} ${FileExists} "$SMSTARTUP\Rainmeter.lnk"
				${NSD_Check} $R3
			${EndIf}

			SetShellVarContext current
			${If} ${FileExists} "$SMSTARTUP\Rainmeter.lnk"
				${NSD_Check} $R3
			${EndIf}
		${EndIf}
	${Else}
		StrCpy $R3 0
	${EndIf}

	${If} $1 != 0
		${NSD_CreateGroupBox} 0 42u -1u $1 "$(ADDITIONALOPTIONS)"
	${EndIf}

	; Show UAC shield on Install button if requiredd
	GetDlgItem $0 $HWNDPARENT 1
	${If} $InstallPortable == 1
		SendMessage $0 ${BCM_SETSHIELD} 0 0
	${Else}
		SendMessage $0 ${BCM_SETSHIELD} 0 1

		; Hide Back button
		GetDlgItem $0 $HWNDPARENT 3
		ShowWindow $0 ${SW_HIDE}
	${EndIf}

	nsDialogs::Show
FunctionEnd

Function PageOptionsDirectoryOnChange
	${NSD_GetText} $R0 $0

	StrCpy $Install64Bit 0
	${If} ${RunningX64}
		${If} ${FileExists} "$0\Rainmeter.exe"
			MoreInfo::GetProductVersion "$0\Rainmeter.exe"
			Pop $0
			StrCpy $0 $0 2 -7
			${If} $0 == 64
				StrCpy $Install64Bit 1
			${EndIf}

			${If} $InstallPortable == 1
				${NSD_SetState} $R3 $Install64Bit
				EnableWindow $R3 0
			${EndIf}
		${Else}
			${If} $InstallPortable == 1
				EnableWindow $R3 1
			${EndIf}
		${EndIf}
	${EndIf}
FunctionEnd

Function PageOptionsBrowseOnClick
	${NSD_GetText} $R0 $0
	nsDialogs::SelectFolderDialog "$(^DirBrowseText)" $0
	Pop $1

	${If} $1 != error
		${If} $InstallPortable == 1
			ClearErrors
			CreateDirectory "$1"
			WriteINIStr "$1\writetest~.rm" "1" "1" "1"

			${If} ${Errors}
				MessageBox MB_OK|MB_ICONEXCLAMATION "$(WRITEERROR)"
			${Else}
				${NSD_SetText} $R0 $1
			${EndIf}

			Delete "$0\writetest~.rm"
			RMDir "$0"
		${Else}
			${NSD_SetText} $R0 $1
		${EndIf}
	${EndIf}
FunctionEnd

Function PageOptionsOnLeave
	GetDlgItem $0 $HWNDPARENT 1
	EnableWindow $0 0

	${If} $R2 != 0
		${NSD_GetState} $R2 $Install64Bit
	${EndIf}

	${If} $R3 != 0
		${NSD_GetState} $R3 $AutoStartup
	${EndIf}

	${NSD_GetText} $R0 $INSTDIR

	${If} $InstallPortable != 1
		${IfNot} ${UAC_IsAdmin}
			; UAC_IsAdmin seems to return incorrect result sometimes. Recheck with UserInfo::GetAccountType to be sure.
			UserInfo::GetAccountType
			Pop $0
			${If} $0 != "Admin"
UAC_TryAgain:
				!insertmacro UAC_RunElevated
				${Switch} $0
				${Case} 0
					${IfThen} $1 = 1 ${|} Quit ${|}
					${IfThen} $3 <> 0 ${|} ${Break} ${|}
					${If} $1 = 3
						MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(ADMINERROR)" /SD IDNO IDOK UAC_TryAgain IDNO 0
					${EndIf}
				${Case} 1223
					Quit
				${Case} 1062
					MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(LOGONERROR)"
					Quit
				${Default}
					MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(UACERROR) ($0)"
					Quit
				${EndSwitch}
			${EndIf}
		${EndIf}
	${EndIf}
FunctionEnd

!macro InstallFiles DIR
	File "..\..\TestBench\${DIR}\Release\Rainmeter.exe"
	File "..\..\TestBench\${DIR}\Release\Rainmeter.dll"
	File "..\..\TestBench\${DIR}\Release\SkinInstaller.exe"

	SetOutPath "$INSTDIR\Plugins"
	File /x *Example*.dll "..\..\TestBench\${DIR}\Release\Plugins\*.dll"
!macroend

!macro RemoveStartMenuShortcuts STARTMENUPATH
	Delete "${STARTMENUPATH}\Rainmeter.lnk"
	Delete "${STARTMENUPATH}\Rainmeter Help.lnk"
	Delete "${STARTMENUPATH}\Rainmeter Help.URL"
	Delete "${STARTMENUPATH}\Remove Rainmeter.lnk"
	Delete "${STARTMENUPATH}\RainThemes.lnk"
	Delete "${STARTMENUPATH}\RainThemes Help.lnk"
	Delete "${STARTMENUPATH}\RainBrowser.lnk"
	Delete "${STARTMENUPATH}\RainBackup.lnk"
	Delete "${STARTMENUPATH}\Rainstaller.lnk"
	Delete "${STARTMENUPATH}\Skin Installer.lnk"
	Delete "${STARTMENUPATH}\Rainstaller Help.lnk"
	RMDir "${STARTMENUPATH}"
!macroend

Section
	SetOutPath "$PLUGINSDIR"
	SetShellVarContext current

	Var /GLOBAL InstArc
	${If} $Install64Bit == 1
		StrCpy $InstArc "x64"
	${Else}
		StrCpy $InstArc "x86"
	${EndIf}

	${If} $InstallPortable != 1
		ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\$InstArc" "Bld"
		${VersionCompare} "$0" "40219" $1

		ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\$InstArc" "Installed"

		; Download and install VC++ redist if required
		${If} $1 == "2"
		${OrIf} $2 != "1"
			${If} ${Silent}
				SetErrorLevel ${ERROR_NOVCREDIST}
				Quit
			${EndIf}

			${If} $Install64Bit != 1
				NSISdl::download /TIMEOUT=30000 "http://download.microsoft.com/download/C/6/D/C6D0FD4E-9E53-4897-9B91-836EBA2AACD3/vcredist_x86.exe" "$PLUGINSDIR\vcredist.exe"
				Pop $0
			${Else}
				NSISdl::download /TIMEOUT=30000 "http://download.microsoft.com/download/A/8/0/A80747C3-41BD-45DF-B505-E9710D2744E0/vcredist_x64.exe" "$PLUGINSDIR\vcredist.exe"
				Pop $0
			${EndIf}

			${If} $0 != "cancel"
			${AndIf} $0 != "success"
				; download from MS failed, try from rainmter.net
				Delete "$PLUGINSDIR\vcredist.exe"

				${If} $Install64Bit != 1
					NSISdl::download /TIMEOUT=30000 "http://rainmeter.net/redist/vc10SP1redist_x86.exe" "$PLUGINSDIR\vcredist.exe"
					Pop $0
				${Else}
					NSISdl::download /TIMEOUT=30000 "http://rainmeter.net/redist/vc10SP1redist_x64.exe" "$PLUGINSDIR\vcredist.exe"
					Pop $0
				${EndIf}
			${EndIf}

			${If} $0 == "success"
				ExecWait '"$PLUGINSDIR\vcredist.exe" /q /norestart' $0
				Delete "$PLUGINSDIR\vcredist.exe"

				${If} $0 == "3010"
					SetRebootFlag true
				${ElseIf} $0 != "0"
					MessageBox MB_OK|MB_ICONSTOP "$(VCINSTERROR)"
					Quit
				${EndIf}
			${ElseIf} $0 == "cancel"
				Quit
			${Else}
				MessageBox MB_OK|MB_ICONSTOP "$(VCINSTERROR)"
				Quit
			${EndIf}
		${EndIf}

		; Download and install .NET if required
		ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Install"
		${If} $0 != "1"
			${If} $Install64Bit != 1
				NSISdl::download /TIMEOUT=30000 "http://download.microsoft.com/download/5/6/7/567758a3-759e-473e-bf8f-52154438565a/dotnetfx.exe" "$PLUGINSDIR\dotnetfx.exe"
			${Else}
				NSISdl::download /TIMEOUT=30000 "http://download.microsoft.com/download/a/3/f/a3f1bf98-18f3-4036-9b68-8e6de530ce0a/NetFx64.exe" "$PLUGINSDIR\dotnetfx.exe"
			${EndIf}

			Pop $0

			${If} $0 != "cancel"
			${AndIf} $0 != "success"
				Delete "$PLUGINSDIR\dotnetfx.exe"

				${If} $Install64Bit != 1
					NSISdl::download /TIMEOUT=30000 "http://rainmeter.net/redist/dotnetfx.exe" "$PLUGINSDIR\dotnetfx.exe"
				${Else}
					NSISdl::download /TIMEOUT=30000 "http://rainmeter.net/redist/NetFx64.exe" "$PLUGINSDIR\dotnetfx.exe"
				${EndIf}

				Pop $0
			${EndIf}

			${If} $0 == "success"
				ExecWait '"$PLUGINSDIR\dotnetfx.exe" /q:a /c:"install /q"' $0
				Delete "$PLUGINSDIR\dotnetfx.exe"

				${If} $0 == "3010"
					SetRebootFlag true
				${ElseIf} $0 != "0"
					MessageBox MB_OK|MB_ICONSTOP "$(DOTNETINSTERROR)"
					Quit
				${EndIf}
			${ElseIf} $0 == "cancel"
				Quit
			${Else}
				MessageBox MB_OK|MB_ICONSTOP "$(DOTNETINSTERROR)"
				Quit
			${EndIf}
		${EndIf}
	${EndIf}

	SetOutPath "$INSTDIR"

	; Close Rainmeter (and wait up to five seconds)
	${ForEach} $0 10 0 - 1
		FindWindow $1 "DummyRainWClass" "Rainmeter control window"
		${If} $1 == 0
			${Break}
		${EndIf}

		SendMessage $1 ${WM_CLOSE} 0 0

		${If} $0 == 0
			${If} ${Silent}
				SetErrorLevel ${ERROR_CLOSEFAIL}
				Quit
			${Else}
				MessageBox MB_RETRYCANCEL|MB_ICONSTOP "$(RAINMETERCLOSEERROR)" IDRETRY +2
				Quit
			${EndIf}
		${EndIf}

		Sleep 500
	${Next}

	; Check if Rainmeter.ini is located in the installation folder and
	; if the installation folder is in Program Files
	${IfNot} ${Silent}
	${AndIf} ${FileExists} "$INSTDIR\Rainmeter.ini"
		${If} $InstallPortable != 1
			!ifdef X64
				StrCmp $INSTDIR "$PROGRAMFILES64\Rainmeter" 0 RainmeterIniDoesntExistLabel
			!else
				StrCmp $INSTDIR "$PROGRAMFILES\Rainmeter" 0 RainmeterIniDoesntExistLabel
			!endif

			MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(SETTINGSFILEERROR)" IDNO RainmeterIniDoesntExistLabel
			CreateDirectory $APPDATA\Rainmeter
			Rename "$INSTDIR\Rainmeter.ini" "$APPDATA\Rainmeter\Rainmeter.ini"
			${If} ${Errors}
				MessageBox MB_OK|MB_ICONSTOP "$(SETTINGSMOVEERROR)"
			${EndIf}
		${Else}
			ReadINIStr $0 "$INSTDIR\Rainmeter.ini" "Rainmeter" "SkinPath"
			${If} $0 == "$INSTDIR\Skins\"
				DeleteINIStr "$INSTDIR\Rainmeter.ini" "Rainmeter" "SkinPath"
			${EndIf}
		${EndIf}
	${EndIf}

RainmeterIniDoesntExistLabel:
	SetOutPath "$INSTDIR"
	Delete "$INSTDIR\Rainmeter.exe.config"
	Delete "$INSTDIR\Rainmeter.chm"
	Delete "$INSTDIR\Default.ini"

!ifdef INCLUDEFILES
	${If} $instArc == "x86"
		!insertmacro InstallFiles "x32"
	${Else}
		!insertmacro InstallFiles "x64"
	${EndIf}

	RMDir /r "$INSTDIR\Languages"
	SetOutPath "$INSTDIR\Languages"
	File "..\..\TestBench\x32\Release\Languages\*.*"

	RMDir /r "$INSTDIR\Addons\Rainstaller"

	SetOutPath "$INSTDIR\Skins"
	RMDir /r "$INSTDIR\Skins\illustro"
	Delete "$INSTDIR\Skins\*.txt"
	File /r "..\Skins\*.*"

	SetOutPath "$INSTDIR\Themes"
	File /r "..\Themes\*.*"
!endif

	SetOutPath "$INSTDIR"

	${If} $InstallPortable != 1
		ReadRegStr $0 HKLM "SOFTWARE\Rainmeter" ""
		WriteRegStr HKLM "SOFTWARE\Rainmeter" "" "$INSTDIR"
		WriteRegStr HKLM "SOFTWARE\Rainmeter" "Language" "$LANGUAGE"
		WriteRegDWORD HKLM "SOFTWARE\Rainmeter" "NonDefault" $NonDefaultLanguage

		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "DisplayName" "Rainmeter"
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "DisplayIcon" "$INSTDIR\Rainmeter.exe,0"
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "URLInfoAbout" "http://rainmeter.net"
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "UninstallString" "$INSTDIR\uninst.exe"

!ifdef BETA
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "DisplayVersion" "${VER} beta r${REV}"
!else
		WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "DisplayVersion" "${VER} r${REV}"
!endif

		WriteRegStr HKCR ".rmskin" "" "Rainmeter skin"
		WriteRegStr HKCR "Rainmeter skin" "" "Rainmeter skin file"
		WriteRegStr HKCR "Rainmeter skin\shell" "" "open"
		WriteRegStr HKCR "Rainmeter skin\DefaultIcon" "" "$INSTDIR\SkinInstaller.exe,0"
		WriteRegStr HKCR "Rainmeter skin\shell\open\command" "" '"$INSTDIR\SkinInstaller.exe" %1'
		WriteRegStr HKCR "Rainmeter skin\shell\edit" "" "Install Rainmeter skin"
		WriteRegStr HKCR "Rainmeter skin\shell\edit\command" "" '"$INSTDIR\SkinInstaller.exe" %1'

		; Refresh shell icons if new install
		${If} $0 == ""
			${RefreshShellIcons}
		${EndIf}

		; Remove all start menu shortcuts
		SetShellVarContext all
		Call RemoveStartMenuShortcuts

		CreateShortcut "$SMPROGRAMS\Rainmeter.lnk" "$INSTDIR\Rainmeter.exe" "" "$INSTDIR\Rainmeter.exe" 0

		SetShellVarContext current
		Call RemoveStartMenuShortcuts

		${If} $AutoStartup == 1
			!insertmacro UAC_AsUser_Call Function CreateStartupShortcut ${UAC_SYNCREGISTERS}
		${EndIf}

		!insertmacro UAC_AsUser_Call Function RemoveStartMenuShortcuts ${UAC_SYNCREGISTERS}

		WriteUninstaller "$INSTDIR\uninst.exe"
	${Else}
		${IfNot} ${FileExists} "Rainmeter.ini"
			CopyFiles /SILENT "$INSTDIR\Themes\illustro default\Rainmeter.thm" "$INSTDIR\Rainmeter.ini"
		${EndIf}

		WriteINIStr "$INSTDIR\Rainmeter.ini" "Rainmeter" "Language" "$LANGUAGE"
	${EndIf}
SectionEnd

Function RemoveStartMenuShortcuts
	!insertmacro RemoveStartMenuShortcuts "$SMPROGRAMS\Rainmeter"
FunctionEnd

Function CreateStartupShortcut
	CreateShortcut  "$SMSTARTUP\Rainmeter.lnk" "$INSTDIR\Rainmeter.exe" "" "$INSTDIR\Rainmeter.exe" 0
FunctionEnd

Function FinishRun
	!insertmacro UAC_AsUser_ExecShell "" "$INSTDIR\Rainmeter.exe" "" "" ""
FunctionEnd


; Uninstall
; --------------------------------------
Function un.onInit
UAC_TryAgain:
	; Request administrative rights
	!insertmacro UAC_RunElevated
	${Switch} $0
	${Case} 0
		${IfThen} $1 = 1 ${|} Quit ${|}
		${IfThen} $3 <> 0 ${|} ${Break} ${|}
		${If} $1 = 3
			MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(ADMINERROR)" /SD IDNO IDOK UAC_TryAgain IDNO 0
		${EndIf}
	${Case} 1223
		Quit
	${Case} 1062
		MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(LOGONERROR)"
		Quit
	${Default}
		MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(UACERROR) ($0)"
		Quit
	${EndSwitch}

	ReadRegStr $0 HKLM "SOFTWARE\Rainmeter" "Language"
	${If} $0 != ""
		StrCpy $LANGUAGE $0
	${EndIf}
FunctionEnd

Function un.PageOptions
	!insertmacro MUI_HEADER_TEXT "$(UNSTALLOPTIONS)" "$(UNSTALLOPTIONSDESC)"
	nsDialogs::Create 1018
	nsDialogs::SetRTL $(^RTL)

	${NSD_CreateCheckbox} 0 0u 95% 12u "$(UNSTALLRAINMETER)"
	Pop $0
	EnableWindow $0 0
	${NSD_Check} $0

	${NSD_CreateCheckbox} 0 15u 70% 12u "$(UNSTALLSETTINGS)"
	Pop $R0

	${NSD_CreateLabel} 16 26u 95% 12u "$(UNSTALLSETTINGSDESC)"

	nsDialogs::Show
FunctionEnd

Function un.GetOptions
	${NSD_GetState} $R0 $un.DeleteAll
FunctionEnd

Section Uninstall
	; Close Rainmeter (and wait up to five seconds)
	${ForEach} $0 10 0 - 1
		FindWindow $1 "DummyRainWClass" "Rainmeter control window"
		${If} $1 == 0
			${Break}
		${EndIf}

		SendMessage $1 ${WM_CLOSE} 0 0

		${If} $0 == 0
			${If} ${Silent}
				SetErrorLevel ${ERROR_CLOSEFAIL}
				Quit
			${Else}
				MessageBox MB_RETRYCANCEL|MB_ICONSTOP "$(RAINMETERCLOSEERROR)" IDRETRY +2
				Quit
			${EndIf}
		${EndIf}

		Sleep 500
	${Next}

	RMDir /r "$TEMP\Rainmeter-Cache"
	RMDir /r "$INSTDIR\Skins\Gnometer"
	RMDir /r "$INSTDIR\Skins\Tranquil"
	RMDir /r "$INSTDIR\Skins\Enigma"
	RMDir /r "$INSTDIR\Skins\Arcs"
	RMDir /r "$INSTDIR\Skins\illustro"
	Delete "$INSTDIR\Skins\*.txt"
	RMDir "$INSTDIR\Skins"

	RMDir /r "$INSTDIR\Addons\RainThemes"
	RMDir /r "$INSTDIR\Addons\RainBrowser"
	RMDir /r "$INSTDIR\Addons\RainBackup"
	RMDir /r "$INSTDIR\Addons\Rainstaller"
	RMDir "$INSTDIR\Addons"
	Delete "$INSTDIR\Plugins\*.*"
	Delete "$INSTDIR\Plugins\Dependencies\*.*"
	RMDir "$INSTDIR\Plugins"
	RMDir /r "$INSTDIR\Languages"
	RMDir /r "$INSTDIR\Themes"
	Delete "$INSTDIR\*.*"

	${If} $un.DeleteAll == 1
		RMDir /r "$INSTDIR\Skins"
		RMDir /r "$INSTDIR\Addons"
		RMDir /r "$INSTDIR\Plugins"
		RMDir /r "$INSTDIR\Fonts"
	${EndIf}

	RMDir "$INSTDIR"

	SetShellVarContext all
	RMDir /r "$APPDATA\Rainstaller"

	SetShellVarContext current
	Call un.RemoveShortcuts
	${If} $un.DeleteAll == 1
		RMDir /r "$APPDATA\Rainmeter"
		RMDir /r "$DOCUMENTS\Rainmeter\Skins"
		RMDir "$DOCUMENTS\Rainmeter"
		RMDir /r "$1\Rainmeter"
	${EndIf}
	
	!insertmacro UAC_AsUser_Call Function un.RemoveShortcuts ${UAC_SYNCREGISTERS}
	${If} $un.DeleteAll == 1
		RMDir /r "$APPDATA\Rainmeter"
		RMDir /r "$DOCUMENTS\Rainmeter\Skins"
		RMDir "$DOCUMENTS\Rainmeter"
	${EndIf}

	SetShellVarContext all
	Call un.RemoveShortcuts
	Delete "$SMPROGRAMS\Rainmeter.lnk"

	DeleteRegKey HKLM "SOFTWARE\Rainmeter"
	DeleteRegKey HKCR ".rmskin"
	DeleteRegKey HKCR "Rainmeter skin"
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter"
	${RefreshShellIcons}
SectionEnd

Function un.RemoveShortcuts
	!insertmacro RemoveStartMenuShortcuts "$SMPROGRAMS\Rainmeter"
	Delete "$SMSTARTUP\Rainmeter.lnk"
	Delete "$DESKTOP\Rainmeter.lnk"
FunctionEnd