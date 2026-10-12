Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

appData = WshShell.ExpandEnvironmentStrings("%APPDATA%")
installDir = fso.GetParentFolderName(WScript.ScriptFullName)
profileDir = appData & "\Braze\profile"

' 1. Copiar perfil se nao existir, ou actualizar ficheiros de configuracao
If Not fso.FolderExists(profileDir) Then
    If Not fso.FolderExists(appData & "\Braze") Then
        fso.CreateFolder(appData & "\Braze")
    End If
    fso.CopyFolder installDir & "\profile", profileDir
Else
    If fso.FileExists(installDir & "\profile\user.js") Then
        On Error Resume Next
        fso.CopyFile installDir & "\profile\user.js", profileDir & "\user.js", True
        On Error GoTo 0
    End If
    If fso.FolderExists(installDir & "\profile\chrome") Then
        On Error Resume Next
        fso.CopyFolder installDir & "\profile\chrome", profileDir & "\chrome", True
        On Error GoTo 0
    End If
End If

' 2. Remover ficheiros de bloqueio antigos (stale locks) se nao estiver nenhum processo ativo
On Error Resume Next
fso.DeleteFile profileDir & "\parent.lock", True
fso.DeleteFile profileDir & "\.parentlock", True
fso.DeleteFile profileDir & "\lock", True
On Error GoTo 0

' 3. Variaveis de ambiente para isolar o processo
WshShell.Environment("PROCESS")("MOZ_APP_NAME") = "braze"
WshShell.Environment("PROCESS")("MOZ_APP_DISPLAYNAME") = "Braze"
WshShell.Environment("PROCESS")("MOZ_APP_VENDOR") = "Braze"

' 4. Lancar braze.exe com -no-remote e abrir a homepage local
homeUrl = "file:///" & Replace(installDir, "\", "/") & "/home/index.html"
cmd = """" & installDir & "\braze.exe"" -no-remote -profile """ & profileDir & """ """ & homeUrl & """"
WshShell.Run cmd, 1, False
