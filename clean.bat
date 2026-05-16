@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%.") do set "ROOT=%%~fI"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\clean_workspace.ps1"
pause
exit /b %ERRORLEVEL%
