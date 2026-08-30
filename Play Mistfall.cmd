@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher\Play-Mistfall.ps1"
if errorlevel 1 pause
