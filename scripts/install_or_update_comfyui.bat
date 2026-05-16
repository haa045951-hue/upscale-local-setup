@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "PORTABLE=%ROOT%\ComfyUI_windows_portable"
set "COMFY=%PORTABLE%\ComfyUI"
set "RUN_NVIDIA=%PORTABLE%\run_nvidia_gpu.bat"
set "UPDATE_BAT=%PORTABLE%\update\update_comfyui.bat"
set "ARCHIVE_DIR=%ROOT%\models_to_download"
set "ARCHIVE=%ARCHIVE_DIR%\ComfyUI_windows_portable_nvidia.7z"
set "ARCHIVE_URL=https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z"

echo.
echo === ComfyUI Windows Portable install/update helper ===
echo Workspace: %ROOT%
echo.

if not exist "%ROOT%" (
    echo ERROR: Workspace folder does not exist:
    echo %ROOT%
    echo Create it first, then run this script again.
    pause
    exit /b 1
)

if not exist "%PORTABLE%" (
    echo Creating download folder:
    echo %ARCHIVE_DIR%
    if not exist "%ARCHIVE_DIR%" mkdir "%ARCHIVE_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not create download folder.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

if not exist "%RUN_NVIDIA%" (
    echo ComfyUI Windows Portable does not appear to be installed yet.
    echo.
    if not exist "%ARCHIVE_DIR%" mkdir "%ARCHIVE_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not create download folder:
        echo %ARCHIVE_DIR%
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )

    where curl >nul 2>nul
    if errorlevel 1 (
        echo ERROR: curl was not found in PATH.
        echo Download manually from:
        echo %ARCHIVE_URL%
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )

    if not exist "%ARCHIVE%" (
        echo Downloading ComfyUI Windows Portable:
        echo %ARCHIVE_URL%
        curl.exe -L --fail --retry 2 --retry-delay 3 --progress-bar -o "%ARCHIVE%" "%ARCHIVE_URL%"
        if errorlevel 1 (
            echo ERROR: Failed to download ComfyUI Windows Portable.
            if exist "%ARCHIVE%" del "%ARCHIVE%"
            if not defined UPSCALE_NO_PAUSE pause
            exit /b 1
        )
    ) else (
        echo Found existing archive:
        echo %ARCHIVE%
    )

    set "SEVENZIP="
    for %%E in (7z.exe 7za.exe 7zz.exe) do (
        if not defined SEVENZIP (
            for /f "delims=" %%P in ('where %%E 2^>nul') do if not defined SEVENZIP set "SEVENZIP=%%P"
        )
    )
    if not defined SEVENZIP if exist "%ProgramFiles%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
    if not defined SEVENZIP if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
    if not defined SEVENZIP (
        echo ERROR: 7-Zip was not found.
        echo Install 7-Zip, then rerun setup.bat.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )

    echo Extracting ComfyUI Windows Portable...
    "%SEVENZIP%" x "%ARCHIVE%" -o"%ROOT%" -y
    if errorlevel 1 (
        echo ERROR: Failed to extract ComfyUI Windows Portable.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )

    if not exist "%RUN_NVIDIA%" (
        echo ERROR: Extraction finished, but launcher is still missing:
        echo %RUN_NVIDIA%
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

echo Found:
echo %RUN_NVIDIA%
echo.

if exist "%UPDATE_BAT%" (
    echo Found official portable updater:
    echo %UPDATE_BAT%
    echo.
    if defined UPSCALE_AUTO_UPDATE (
        set "RUNUPDATE=Y"
    ) else (
        set /p RUNUPDATE=Run the ComfyUI portable updater now? This will modify the existing ComfyUI install. Type Y to continue: 
    )
    if /I "!RUNUPDATE!"=="Y" (
        echo Running updater...
        call "%UPDATE_BAT%"
        echo.
        echo Updater finished. Review messages above for errors.
    ) else (
        echo Skipped update.
    )
) else (
    echo No portable updater found at:
    echo %UPDATE_BAT%
    echo.
    echo If you need to update, follow the official portable instructions:
    echo https://docs.comfy.org/installation/comfyui_portable_windows
)

echo.
echo Done.
if not defined UPSCALE_NO_PAUSE pause
endlocal
