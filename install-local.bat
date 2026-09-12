@echo off
rem ===========================================================================
rem  XozHub.GPT - installation LOCALE
rem  Aucun besoin de GitHub ni d'internet : copie les fichiers de ce dossier
rem  vers %USERPROFILE%\XozHub et ajoute le dossier au PATH utilisateur.
rem
rem  Double-clique ce fichier, ou lance-le depuis un cmd.
rem ===========================================================================
setlocal EnableExtensions
title XozHub.GPT - Installation locale

rem le dossier du script se termine toujours par un anti-slash : on le retire,
rem sinon l'argument recu par PowerShell finit par un anti-slash qui echappe
rem le guillemet fermant et la valeur est tronquee.
set "SRC=%~dp0"
if "%SRC:~-1%"=="\" set "SRC=%SRC:~0,-1%"

set "PS1=%SRC%\install.ps1"

if not exist "%PS1%" (
    echo.
    echo   [X] install.ps1 est introuvable dans :
    echo       "%SRC%"
    echo.
    echo       Garde install-local.bat a cote des autres fichiers
    echo       ^(install.ps1, xozhub.ps1, xozhub.bat...^).
    echo.
    pause
    exit /b 1
)

if not exist "%SRC%\xozhub.ps1" (
    echo.
    echo   [X] xozhub.ps1 est introuvable dans "%SRC%".
    echo       Tous les fichiers doivent rester dans le meme dossier.
    echo.
    pause
    exit /b 1
)

cls
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%PS1%" -Source "%SRC%"
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
    echo   Installation interrompue ^(code %RC%^).
    echo.
)
pause
exit /b %RC%
