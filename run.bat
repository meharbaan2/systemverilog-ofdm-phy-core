@echo off
setlocal

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1"
set EXITCODE=%ERRORLEVEL%

echo.
if "%EXITCODE%"=="0" (
    echo Summary: OFDM PHY sanity test PASSED.
) else (
    echo Summary: OFDM PHY sanity test FAILED with exit code %EXITCODE%.
)
echo.
pause
exit /b %EXITCODE%
