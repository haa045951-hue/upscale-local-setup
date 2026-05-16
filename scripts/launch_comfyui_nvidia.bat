@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "PORTABLE=%ROOT%\ComfyUI_windows_portable"
set "RUN_NVIDIA=%PORTABLE%\run_nvidia_gpu.bat"

echo.
echo === Launch ComfyUI NVIDIA ===
echo.

if not exist "%ROOT%" (
    echo ERROR: Workspace folder does not exist:
    echo %ROOT%
    pause
    exit /b 1
)

if not exist "%RUN_NVIDIA%" (
    echo ERROR: ComfyUI NVIDIA launcher was not found:
    echo %RUN_NVIDIA%
    echo.
    echo Download and extract ComfyUI Windows Portable from:
    echo https://docs.comfy.org/installation/comfyui_portable_windows
    echo.
    echo Extract it so run_nvidia_gpu.bat is directly inside:
    echo %PORTABLE%
    pause
    exit /b 1
)

echo Starting ComfyUI with NVIDIA launcher...
echo After it finishes loading, open:
echo http://127.0.0.1:8188
echo.

cd /d "%PORTABLE%"
call "%RUN_NVIDIA%"

echo.
echo ComfyUI process ended or launcher returned.
echo Open this URL while ComfyUI is running:
echo http://127.0.0.1:8188
pause
endlocal
