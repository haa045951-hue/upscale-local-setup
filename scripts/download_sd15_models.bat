@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "CHECKPOINTS=%ROOT%\ComfyUI_windows_portable\ComfyUI\models\checkpoints"
set "VAE=%ROOT%\ComfyUI_windows_portable\ComfyUI\models\vae"

echo.
echo === SD 1.5 checkpoint and VAE downloader ===
echo.

if not exist "%CHECKPOINTS%" mkdir "%CHECKPOINTS%"
if not exist "%VAE%" mkdir "%VAE%"

where curl >nul 2>nul
if errorlevel 1 (
    echo ERROR: curl was not found in PATH.
    if not defined UPSCALE_NO_PAUSE pause
    exit /b 1
)

call :download_if_missing "%CHECKPOINTS%\realisticVisionV60B1_v60B1VAE.safetensors" "https://civitai.com/api/download/models/245598"
if errorlevel 1 goto failed
call :download_if_missing "%CHECKPOINTS%\epicrealism_naturalSinRC1VAE.safetensors" "https://civitai.com/api/download/models/143906"
if errorlevel 1 goto failed
call :download_if_missing "%CHECKPOINTS%\meinamix_v12Final.safetensors" "https://huggingface.co/andro-flock/MeinaMix-V12_-Final/resolve/main/original_sd_checkpoint.safetensors"
if errorlevel 1 goto failed
call :download_if_missing "%CHECKPOINTS%\Counterfeit-V3.0_fix_fp16.safetensors" "https://huggingface.co/Lank1906/Counterfeit-V3.0/resolve/main/Counterfeit-V3.0_fix_fp16.safetensors"
if errorlevel 1 goto failed
call :download_if_missing "%CHECKPOINTS%\dreamshaper_8.safetensors" "https://civitai.com/api/download/models/128713"
if errorlevel 1 goto failed
call :download_if_missing "%CHECKPOINTS%\revAnimated_v122.safetensors" "https://huggingface.co/botp/ReVAnimated/resolve/main/revAnimated_v122.safetensors"
if errorlevel 1 goto failed
call :download_if_missing "%VAE%\vae-ft-mse-840000-ema-pruned.safetensors" "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
if errorlevel 1 goto failed

echo.
echo SD 1.5 model download step finished.
if not defined UPSCALE_NO_PAUSE pause
exit /b 0

:download_if_missing
set "FILE_PATH=%~1"
set "FILE_URL=%~2"
if exist "%FILE_PATH%" (
    echo OK: %FILE_PATH% already exists. Skipping.
    exit /b 0
)
echo Downloading:
echo %FILE_PATH%
curl.exe -L --fail --retry 2 --retry-delay 3 --progress-bar -o "%FILE_PATH%" "%FILE_URL%"
if errorlevel 1 (
    echo ERROR: Download failed:
    echo %FILE_URL%
    if exist "%FILE_PATH%" del "%FILE_PATH%"
    exit /b 1
)
exit /b 0

:failed
echo.
echo One or more downloads failed. See MODEL_DOWNLOAD_INSTRUCTIONS.txt for manual links.
if not defined UPSCALE_NO_PAUSE pause
exit /b 1
