@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "PORTABLE=%ROOT%\ComfyUI_windows_portable"
set "COMFY=%PORTABLE%\ComfyUI"
set "CUSTOM_NODES=%COMFY%\custom_nodes"
set "PYTHON=%PORTABLE%\python_embeded\python.exe"

echo.
echo === ComfyUI custom node installer ===
echo Workspace: %ROOT%
echo.

if not exist "%ROOT%" (
    echo ERROR: Workspace folder does not exist:
    echo %ROOT%
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

if not exist "%COMFY%" (
    echo ERROR: ComfyUI folder was not found:
    echo %COMFY%
    echo.
    echo Download and extract ComfyUI Windows Portable first:
    echo https://docs.comfy.org/installation/comfyui_portable_windows
    echo.
    echo Expected portable launch file:
    echo %PORTABLE%\run_nvidia_gpu.bat
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

if not exist "%PYTHON%" (
    echo ERROR: Embedded ComfyUI Python was not found:
    echo %PYTHON%
    echo Recheck the ComfyUI Windows Portable extraction.
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: git was not found in PATH.
    echo Install Git for Windows from the official site, then rerun this script:
    echo https://git-scm.com/download/win
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

if not exist "%CUSTOM_NODES%" (
    echo Creating custom_nodes folder:
    echo %CUSTOM_NODES%
    mkdir "%CUSTOM_NODES%"
    if errorlevel 1 (
        echo ERROR: Could not create custom_nodes folder.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

cd /d "%CUSTOM_NODES%"
if errorlevel 1 (
    echo ERROR: Could not enter:
    echo %CUSTOM_NODES%
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

echo.
echo Installing missing custom nodes only. Existing folders will not be overwritten.
echo.

if exist "ComfyUI-Manager" (
    echo OK: ComfyUI-Manager already exists. Skipping clone.
) else (
    echo Cloning ComfyUI Manager...
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git
    if errorlevel 1 (
        echo ERROR: Failed to clone ComfyUI Manager.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

if exist "ComfyUI_UltimateSDUpscale" (
    echo OK: ComfyUI_UltimateSDUpscale already exists. Skipping clone.
) else (
    echo Cloning Ultimate SD Upscale...
    git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git
    if errorlevel 1 (
        echo ERROR: Failed to clone Ultimate SD Upscale.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

if exist "comfyui_controlnet_aux" (
    echo OK: comfyui_controlnet_aux already exists. Skipping clone.
) else (
    echo Cloning ControlNet Aux...
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git
    if errorlevel 1 (
        echo ERROR: Failed to clone ControlNet Aux.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

if exist "was-ns" (
    echo OK: was-ns already exists. Skipping clone.
) else (
    echo Cloning WAS Node Suite...
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git was-ns
    if errorlevel 1 (
        echo ERROR: Failed to clone WAS Node Suite.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

echo.
echo Installing custom node Python requirements with embedded ComfyUI Python...

if exist "%CUSTOM_NODES%\ComfyUI-Manager\requirements.txt" (
    echo Installing ComfyUI Manager requirements...
    "%PYTHON%" -m pip install -r "%CUSTOM_NODES%\ComfyUI-Manager\requirements.txt"
    if errorlevel 1 (
        echo ERROR: Failed to install ComfyUI Manager requirements.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
) else (
    echo No ComfyUI Manager requirements.txt found. Skipping.
)

if exist "%CUSTOM_NODES%\comfyui_controlnet_aux\requirements.txt" (
    echo Installing ControlNet Aux requirements...
    "%PYTHON%" -m pip install -r "%CUSTOM_NODES%\comfyui_controlnet_aux\requirements.txt"
    if errorlevel 1 (
        echo ERROR: Failed to install ControlNet Aux requirements.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
) else (
    echo No ControlNet Aux requirements.txt found. Skipping.
)

if exist "%CUSTOM_NODES%\was-ns\requirements.txt" (
    echo Installing WAS Node Suite requirements...
    "%PYTHON%" -m pip install -r "%CUSTOM_NODES%\was-ns\requirements.txt"
    if errorlevel 1 (
        echo ERROR: Failed to install WAS Node Suite requirements.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
) else (
    echo No WAS Node Suite requirements.txt found. Skipping.
)

echo.
echo Custom node install step finished.
echo Restart ComfyUI after installing or updating custom nodes.
if not defined UPSCALE_NO_PAUSE pause
endlocal
