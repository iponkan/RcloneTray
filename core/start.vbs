Option Explicit
Dim ws, fso, currentDir, psScript

Set ws = CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

currentDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript = chr(34) & currentDir & "\tray.ps1" & chr(34)

' Run tray.ps1 using PowerShell
' -WindowStyle Hidden: Completely hide the console window
' -ExecutionPolicy Bypass: Prevent permission issues from blocking execution
ws.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File " & psScript, 0, False