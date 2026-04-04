@echo off

echo Enter the target IP address:
set /p remoteIP=

echo Enter the username (include domain if required):
set /p userName=

echo Enter the password:
set /p userPass=

REM Execute PsExec to connect to the remote host
psexec \\%remoteIP% -i -s -u "%userName%" -p "%userPass%" cmd.exe


)
