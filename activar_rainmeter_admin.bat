@echo off
setlocal
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [1/3] Quitando inicio normal de Rainmeter (usuario comun)...
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Rainmeter.lnk" (
    del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Rainmeter.lnk"
)

echo [2/3] Creando tarea programada RainmeterAdmin (inicio elevado al iniciar sesion)...
set "RM=C:\Program Files\Rainmeter\Rainmeter.exe"
if not exist "%RM%" set "RM=C:\Program Files (x86)\Rainmeter\Rainmeter.exe"

powershell -NoProfile -Command ^
  "$action = New-ScheduledTaskAction -Execute '%RM%';" ^
  "$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME;" ^
  "$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest;" ^
  "$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Seconds 0);" ^
  "Register-ScheduledTask -TaskName 'RainmeterAdmin' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null"

echo [3/3] Reiniciando Rainmeter como administrador...
taskkill /F /IM Rainmeter.exe >nul 2>&1
timeout /t 1 /nobreak >nul
schtasks /Run /TN "RainmeterAdmin" >nul 2>&1

echo.
echo Listo! Rainmeter ahora arranca siempre como administrador (sin cartel UAC).
timeout /t 2 /nobreak >nul
