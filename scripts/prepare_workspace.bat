@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"

for %%D in (
    "input"
    "output"
    "logs"
    "input_batch\photos"
    "input_batch\anime"
    "input_batch\digital_art"
    "input_batch\safe_restore"
    "output_batch\photos\4x"
    "output_batch\photos\final"
    "output_batch\anime\4x"
    "output_batch\anime\final"
    "output_batch\digital_art\4x"
    "output_batch\digital_art\final"
    "output_batch\safe_restore\4x"
    "output_batch\safe_restore\final"
) do (
    if not exist "%ROOT%\%%~D" mkdir "%ROOT%\%%~D"
    if errorlevel 1 (
        echo ERROR: Could not create %ROOT%\%%~D
        exit /b 1
    )
    if not exist "%ROOT%\%%~D\.gitkeep" type nul > "%ROOT%\%%~D\.gitkeep"
)

exit /b 0
