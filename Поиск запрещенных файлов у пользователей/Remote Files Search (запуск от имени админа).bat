@echo off
setlocal EnableExtensions

set "src=%~dp0EverythingPortable"
set "userName=DOMAIN\ADMIN_USER"
set "remoteInstallDir=C:\!install\Tools\Everything"

if not exist "%~dp0PsExec.exe" (
    echo PsExec.exe not found next to the script.
    exit /b 1
)

if not exist "%src%\Everything.exe" (
    echo EverythingPortable folder not found.
    exit /b 1
)

set /p "remoteIP=IP ili imya PC: "
if not defined remoteIP exit /b 1

set /p "inputUser=Admin login [%userName%]: "
if defined inputUser set "userName=%inputUser%"

set /p "userPass=Admin password: "
if not defined userPass exit /b 1

robocopy "%src%" "\\%remoteIP%\c$\!install\Tools\Everything" /E /R:1 /W:1 >nul
if errorlevel 8 exit /b 1

"%~dp0PsExec.exe" \\%remoteIP% -accepteula -u "%userName%" -p "%userPass%" -s -d "%remoteInstallDir%\Everything.exe" -startup
if errorlevel 1 exit /b 1

echo Done. Open Everything64.exe locally and connect to %remoteIP%.
endlocal
