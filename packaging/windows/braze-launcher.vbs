Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

appData = WshShell.ExpandEnvironmentStrings("%APPDATA%")
installDir = fso.GetParentFolderName(WScript.ScriptFullName)
profileDir = appData & "\Braze\profile"

' 1. Garantir que a estrutura de pastas existe no APPDATA
If Not fso.FolderExists(appData & "\Braze") Then
    fso.CreateFolder(appData & "\Braze")
End If
If Not fso.FolderExists(profileDir) Then
    fso.CreateFolder(profileDir)
End If
If Not fso.FolderExists(profileDir & "\chrome") Then
    fso.CreateFolder(profileDir & "\chrome")
End If
If Not fso.FolderExists(profileDir & "\extensions") Then
    fso.CreateFolder(profileDir & "\extensions")
End If

' 2. Sincronizar configuracoes, estilos do chrome e extensoes
On Error Resume Next
If fso.FileExists(installDir & "\profile\user.js") Then
    fso.CopyFile installDir & "\profile\user.js", profileDir & "\user.js", True
End If
If fso.FolderExists(installDir & "\profile\chrome") Then
    fso.CopyFile installDir & "\profile\chrome\*.*", profileDir & "\chrome\", True
End If
If fso.FolderExists(installDir & "\profile\extensions") Then
    fso.CopyFile installDir & "\profile\extensions\*.*", profileDir & "\extensions\", True
End If
On Error GoTo 0

' 3. Remover ficheiros de bloqueio antigos (stale locks) se nao estiver nenhum processo ativo
On Error Resume Next
fso.DeleteFile profileDir & "\parent.lock", True
fso.DeleteFile profileDir & "\.parentlock", True
fso.DeleteFile profileDir & "\lock", True
On Error GoTo 0

' 4. Variaveis de ambiente para isolar o processo
WshShell.Environment("PROCESS")("MOZ_APP_NAME") = "braze"
WshShell.Environment("PROCESS")("MOZ_APP_DISPLAYNAME") = "Braze"
WshShell.Environment("PROCESS")("MOZ_APP_VENDOR") = "Braze"

' 5. Lancar braze.exe com -no-remote e abrir a homepage local
homeUrl = "file:///" & Replace(installDir, "\", "/") & "/home/index.html"
cmd = """" & installDir & "\braze.exe"" -no-remote -profile """ & profileDir & """ """ & homeUrl & """"
WshShell.Run cmd, 1, False
