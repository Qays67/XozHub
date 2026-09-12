@echo off
rem ===========================================================================
rem  XozHub.GPT - desinstalleur (amorce pour cmd.exe)
rem  Telecharge uninstall.ps1 puis l'execute.
rem ===========================================================================
setlocal EnableExtensions
title XozHub.GPT - Desinstallation

set "REPO_RAW=https://raw.githubusercontent.com/Qays67/XozHub/main"
if not "%~1"=="" set "REPO_RAW=%~1"
set "TMP_PS=%TEMP%\xozhub-uninstall.ps1"

echo.

where curl >nul 2>&1
if errorlevel 1 goto :ps

curl -fsSL "%REPO_RAW%/uninstall.ps1" -o "%TMP_PS%"
if errorlevel 1 goto :fail
goto :run

:ps
echo   curl.exe introuvable : telechargement via PowerShell...
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%REPO_RAW%/uninstall.ps1' -OutFile '%TMP_PS%' -UseBasicParsing -ErrorAction Stop } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 goto :fail

:run
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%TMP_PS%"
set "RC=%ERRORLEVEL%"
del "%TMP_PS%" >nul 2>&1
exit /b %RC%

:fail
echo.
echo   [X] Echec du telechargement du desinstalleur.
echo.
echo   URL testee :
echo     %REPO_RAW%/uninstall.ps1
echo.
pause
exit /b 1
