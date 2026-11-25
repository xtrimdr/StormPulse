@echo off
setlocal
set "SRC=%~dp0StormPulse"
set "DST=%USERPROFILE%\Documents\Rainmeter\Skins\StormPulse"

echo Instalando StormPulse en "%DST%"...
xcopy "%SRC%" "%DST%" /E /I /Y >nul
if errorlevel 1 (
    echo Error al copiar los archivos.
    pause
    exit /b 1
)

set "RM=C:\Program Files\Rainmeter\Rainmeter.exe"
if not exist "%RM%" set "RM=C:\Program Files (x86)\Rainmeter\Rainmeter.exe"

if exist "%RM%" (
    "%RM%" !RefreshApp
    timeout /t 1 /nobreak >nul
    "%RM%" !ActivateConfig "StormPulse\Panel" "Panel.ini"
    echo StormPulse instalado y activado en Rainmeter!
) else (
    echo StormPulse copiado. Abri Rainmeter y activa StormPulse\Panel\Panel.ini.
)
pause
