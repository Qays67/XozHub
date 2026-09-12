@echo off
rem ===========================================================================
rem  XozHub.GPT - lanceur pour l'invite de commandes Windows (cmd.exe)
rem ===========================================================================
setlocal EnableExtensions
set "XOZHUB_DIR=%~dp0"
set "XOZHUB_PS=%XOZHUB_DIR%xozhub.ps1"

if not exist "%XOZHUB_PS%" (
    echo.
    echo   [X] Fichier introuvable : "%XOZHUB_PS%"
    echo       Reinstalle avec la commande du site.
    echo.
    exit /b 1
)

rem --- sauvegarde de la page de codes courante -------------------------------
set "OLDCP="
for /f "tokens=2 delims=:" %%a in ('chcp 2^>nul') do set "OLDCP=%%a"
set "OLDCP=%OLDCP: =%"

rem --- UTF-8 pour les accents et les blocs de la banniere --------------------
chcp 65001 >nul 2>&1

title XozHub.GPT

rem --- PowerShell 7 si dispo, sinon Windows PowerShell 5.1 -------------------
set "PS_EXE=powershell"
where pwsh >nul 2>&1 && set "PS_EXE=pwsh"

"%PS_EXE%" -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%XOZHUB_PS%" %*
set "RC=%ERRORLEVEL%"

if defined OLDCP chcp %OLDCP% >nul 2>&1

endlocal & exit /b %RC%
