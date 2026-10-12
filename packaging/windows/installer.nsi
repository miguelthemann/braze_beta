!include "MUI2.nsh"

!ifndef VERSION
  !define VERSION "1.0.0"
!endif

Name "Braze Browser"
OutFile "..\..\Braze-Setup-${VERSION}.exe"
InstallDir "$PROGRAMFILES64\Braze"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Italian"

Section "Braze Core" SecCore
  SetOutPath "$INSTDIR"
  
  # Terminar processos anteriores do braze.exe que possam estar a bloquear ficheiros ou o perfil
  ExecWait 'taskkill /F /IM braze.exe'

  # The runner will drop the prepared files into build-win\Braze
  File /r "..\..\build-win\Braze\*"

  # Create an invisible launcher script in VBScript to run python loader + braze.exe silently
  # Alternatively, just create a shortcut with arguments
  CreateDirectory "$SMPROGRAMS\Braze"
  
  # Create an invisible launcher script in VBScript to run python loader + braze.exe silently
  # The launcher copies the profile to %APPDATA% so standard users can write to it without permissions errors
  CreateShortcut "$SMPROGRAMS\Braze\Braze.lnk" "$INSTDIR\braze-launcher.vbs" "" "$INSTDIR\assets\icon.ico"
  CreateShortcut "$DESKTOP\Braze.lnk" "$INSTDIR\braze-launcher.vbs" "" "$INSTDIR\assets\icon.ico"
  
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  # Register in Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Braze" "DisplayName" "Braze Browser"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Braze" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Braze" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Braze" "Publisher" "Miguel The Mann"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Braze" "DisplayIcon" "$\"$INSTDIR\braze.exe$\",0"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Braze.lnk"
  Delete "$SMPROGRAMS\Braze\Braze.lnk"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Braze"
SectionEnd
