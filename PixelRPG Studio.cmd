@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher\Start-PixelRPG.ps1" %*
if errorlevel 1 pause
endlocal
