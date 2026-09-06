@echo off
REM Instalador de doble clic para Windows.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo Puedes cerrar esta ventana.
pause
