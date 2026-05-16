@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"
set "PYTHON=%ROOT%\ComfyUI_windows_portable\python_embeded\python.exe"

echo.
echo === 4x-UltraSharp plus final Lanczos 16K batch ===
echo Input:  %ROOT%\input_batch\until_16k
echo Output: %ROOT%\output_batch\ultrasharp_min16k
echo.

if not exist "%PYTHON%" (
    echo ERROR: Embedded ComfyUI Python was not found:
    echo %PYTHON%
    echo Run setup.bat first.
    pause
    exit /b 1
)

"%PYTHON%" "%ROOT%\scripts\ultrasharp_until_16k.py"
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
    echo Ultrasharp batch finished.
) else (
    echo Ultrasharp batch failed. Review messages above and logs\ultrasharp_until_16k.csv.
)
pause
exit /b %RESULT%
