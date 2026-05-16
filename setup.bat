@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%.") do set "ROOT=%%~fI"

echo.
echo === Upscale local setup ===
echo Workspace: %ROOT%
echo.

set "UPSCALE_NO_PAUSE=1"
set "UPSCALE_AUTO_UPDATE=1"

call "%ROOT%\scripts\prepare_workspace.bat"
if errorlevel 1 goto failed

call "%ROOT%\scripts\install_or_update_comfyui.bat"
if errorlevel 1 goto failed

call "%ROOT%\scripts\install_custom_nodes.bat"
if errorlevel 1 goto failed

call "%ROOT%\scripts\download_upscale_models.bat"
if errorlevel 1 goto failed

call "%ROOT%\scripts\download_sd15_models.bat"
if errorlevel 1 goto failed

echo.
echo Setup finished.
echo Launch ComfyUI with:
echo scripts\launch_comfyui_nvidia.bat
echo.
pause
exit /b 0

:failed
echo.
echo Setup failed. Review the message above.
pause
exit /b 1
