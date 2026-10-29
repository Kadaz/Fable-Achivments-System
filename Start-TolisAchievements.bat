@echo off
setlocal
set "SCRIPT=%~dp0FableAchievements.ps1"
set "PS=%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%SCRIPT%" (
    echo ERROR: FableAchievements.ps1 was not found next to this file.
    pause
    exit /b 1
)

start "" "%PS%" -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
endlocal
