@echo off
setlocal
cd /d "%~dp0"
echo Starting Mistfall dedicated server on UDP 27180...
"Mistfall-Bell-Seasons.exe" --headless -- --server --port=27180 --max-clients=8 --server-name="Mistfall Dedicated" --world=mistfall --farm-mode=shared --relationship-mode=independent
echo.
echo Server stopped. Review the message above before closing this window.
pause
endlocal
