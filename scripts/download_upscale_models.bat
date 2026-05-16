@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "PORTABLE=%ROOT%\ComfyUI_windows_portable"
set "MODEL_DIR=%PORTABLE%\ComfyUI\models\upscale_models"

echo.
echo === Upscale model downloader ===
echo.

if not exist "%ROOT%" (
    echo ERROR: Workspace folder does not exist:
    echo %ROOT%
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

if not exist "%MODEL_DIR%" (
    echo Creating upscale model folder:
    echo %MODEL_DIR%
    mkdir "%MODEL_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not create upscale model folder.
        if not defined UPSCALE_NO_PAUSE pause
        exit /b 1
    )
)

where curl >nul 2>nul
if errorlevel 1 (
    echo ERROR: curl was not found in PATH.
    echo Windows 10/11 normally includes curl.exe. Download models manually if unavailable.
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

call :download_if_missing "4x-UltraSharp.pth" "https://huggingface.co/lokCX/4x-Ultrasharp/resolve/main/4x-UltraSharp.pth"
if errorlevel 1 goto failed

call :download_if_missing "RealESRGAN_x4plus.pth" "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"
if errorlevel 1 goto failed

call :download_if_missing "BSRGAN.pth" "https://github.com/cszn/KAIR/releases/download/v1.0/BSRGAN.pth"
if errorlevel 1 goto failed

call :download_if_missing "RealESRGAN_x4plus_anime_6B.pth" "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth"
if errorlevel 1 goto failed

echo.
echo Upscale model download step finished.
if not defined UPSCALE_NO_PAUSE pause
exit /b 0

:download_if_missing
set "FILE_NAME=%~1"
set "FILE_URL=%~2"
set "FILE_PATH=%MODEL_DIR%\%FILE_NAME%"

if exist "%FILE_PATH%" (
    echo OK: %FILE_NAME% already exists. Skipping download.
    exit /b 0
)

echo Downloading %FILE_NAME%...
curl.exe -L --fail --progress-bar -o "%FILE_PATH%" "%FILE_URL%"
if errorlevel 1 (
    echo ERROR: Failed to download %FILE_NAME%.
    if exist "%FILE_PATH%" (
        echo A partial file may exist here:
        echo %FILE_PATH%
    )
    exit /b 1
)

echo OK: Downloaded %FILE_NAME%
exit /b 0

:failed
echo.
echo One or more model downloads failed. Review the messages above.
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
