@echo off
title Julmust Arcade
cd /d "%~dp0"

rem start the local web server (a minimized window appears - keep it open while playing)
start "Julmust Arcade server" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_start-server.ps1"

rem give the server a moment, then open the arcade in your default browser
timeout /t 1 /nobreak >nul
start "" http://localhost:8765/

echo.
echo   Julmust Arcade is starting: http://localhost:8765/
echo   (close the minimized server window to stop the arcade)
echo.
timeout /t 4 >nul
