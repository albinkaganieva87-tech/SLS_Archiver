Option Explicit

Dim fso, shell, scriptPath, psCommand

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "Sussy.ps1")

If Not fso.FileExists(scriptPath) Then
    MsgBox "Файл Sussy.ps1 не найден!" & vbCrLf & vbCrLf & _
           "Ожидаемый путь:" & vbCrLf & _
           scriptPath, _
           vbCritical + vbOKOnly, _
           "SLS Archivizer - Ошибка"
    WScript.Quit 1
End If

psCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptPath & """"

shell.Run psCommand, 1, False

Set shell = Nothing
Set fso = Nothing
