@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "PORTABLE=%ROOT%\ComfyUI_windows_portable"
set "UPSCALE_MODELS=%PORTABLE%\ComfyUI\models\upscale_models"
set "CHECKPOINTS=%PORTABLE%\ComfyUI\models\checkpoints"
set "INPUT=%ROOT%\input"
set "OUTPUT=%ROOT%\output"
set "WORKFLOWS=%ROOT%\workflows"

echo.
echo === Open workspace folders ===
echo.

if not exist "%ROOT%" (
    echo ERROR: Workspace folder does not exist:
    echo %ROOT%
    pause
    exit /b 1
)

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"
if not exist "%WORKFLOWS%" mkdir "%WORKFLOWS%"

if not exist "%UPSCALE_MODELS%" (
    echo Missing upscale model folder:
    echo %UPSCALE_MODELS%
    echo It will exist after ComfyUI Windows Portable is extracted.
) else (
    echo Opening upscale model folder...
    start "" explorer "%UPSCALE_MODELS%"
)

if not exist "%CHECKPOINTS%" (
    echo Missing checkpoint folder:
    echo %CHECKPOINTS%
    echo It will exist after ComfyUI Windows Portable is extracted.
) else (
    echo Opening checkpoint folder...
    start "" explorer "%CHECKPOINTS%"
)

echo Opening input folder...
start "" explorer "%INPUT%"

echo Opening output folder...
start "" explorer "%OUTPUT%"

echo Opening workflows folder...
start "" explorer "%WORKFLOWS%"

echo.
echo Done.
pause
endlocal
