@echo off
rem ===========================================================================
rem  XozHub.GPT - installeur (amorce pour cmd.exe)
rem  Telecharge install.ps1 puis l'execute.
rem
rem  Le 1er argument (optionnel) remplace l'URL de base : le site transmet
rem  automatiquement son propre domaine, donc ces fichiers marchent sur
rem  n'importe quel hebergeur, sans rien modifier ici.
rem ===========================================================================
setlocal EnableExtensions
title XozHub.GPT - Installation

set "REPO_RAW=https://raw.githubusercontent.com/Qays67/XozHub/main"
if not "%~1"=="" set "REPO_RAW=%~1"
set "TMP_PS=%TEMP%\xozhub-install.ps1"

echo.
echo   XozHub.GPT - Installation
echo   ---------------------------------------------------------
echo.

rem --- 1. telechargement : curl.exe si present, sinon PowerShell -------------
where curl >nul 2>&1
if errorlevel 1 goto :ps

echo   [1/2] Telechargement de l'installeur (curl)...
curl -fsSL "%REPO_RAW%/install.ps1" -o "%TMP_PS%"
if errorlevel 1 goto :fail
goto :run

:ps
echo   [1/2] curl.exe introuvable : telechargement via PowerShell...
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%REPO_RAW%/install.ps1' -OutFile '%TMP_PS%' -UseBasicParsing -ErrorAction Stop } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 goto :fail

:run
echo   [2/2] Installation en cours...
echo.
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%TMP_PS%" -Base "%REPO_RAW%"
set "RC=%ERRORLEVEL%"
del "%TMP_PS%" >nul 2>&1

echo   ---------------------------------------------------------
if "%RC%"=="0" (
    echo   Ouvre un NOUVEAU cmd puis tape : xozhub
) else (
    echo   L'installation a echoue ^(code %RC%^).
)
echo.
pause
exit /b %RC%

:fail
echo.
echo   [X] Impossible de telecharger l'installeur.
echo.
echo       - verifie ta connexion internet
echo       - verifie que les fichiers sont bien en ligne a cette adresse
echo.
echo   URL testee :
echo     %REPO_RAW%/install.ps1
echo.
echo   Sans internet ni GitHub : ouvre le dossier du projet et
echo   double-clique install-local.bat
echo.
pause
exit /b 1
