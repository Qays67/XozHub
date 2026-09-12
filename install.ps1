#Requires -Version 5.1
<#
    XozHub.GPT - installeur

    Deux modes :
      1) en ligne  : telecharge les fichiers depuis l'hebergeur (GitHub par defaut)
                     -> powershell -File install.ps1
                     -> ou via  irm https://.../install.ps1 | iex
      2) local     : copie les fichiers depuis un dossier deja present
                     -> powershell -File install.ps1 -Source "C:\chemin\XozHub\"
                     (utilise par install-local.bat, aucun besoin d'internet)

    Dans les deux cas : cible %USERPROFILE%\XozHub, puis ajoute au PATH utilisateur.

    -Base <url>  : hebergeur ou sont les fichiers (sinon GitHub par defaut).
                   Le site le transmet tout seul, et la variable
                   d'environnement XOZHUB_BASE sert de repli quand le script
                   est lance via "irm ... | iex".
#>
param(
    [string]$Source = '',
    [string]$Base   = ''
)

$ErrorActionPreference = 'Stop'

$RepoRaw = 'https://raw.githubusercontent.com/Qays67/XozHub/main'
if (-not $Base) { $Base = $env:XOZHUB_BASE }
if ($Base) { $RepoRaw = $Base.TrimEnd('/') }
$Target  = Join-Path $env:USERPROFILE 'XozHub'
$Files   = @('xozhub.ps1', 'xozhub.bat', 'uninstall.ps1', 'uninstall.bat')

function Write-Line {
    param([string]$T = '', [string]$C = 'Gray')
    Write-Host $T -ForegroundColor $C
}

Write-Host ''
Write-Line '   +=======================================================+' 'Magenta'
Write-Line '   |          X O Z H U B . G P T   -   I N S T A L L      |' 'Cyan'
Write-Line '   |                                                       |' 'Magenta'
Write-Line '   |   Assistant IA pour le terminal Windows               |' 'DarkGray'
Write-Line '   +=======================================================+' 'Magenta'
Write-Host ''

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

# --- 1. dossier cible ------------------------------------------------------
$Mode = if ($Source) { 'local' } else { 'en ligne' }
Write-Line "  [1/4] Dossier cible : $Target   (mode $Mode)" 'Gray'
if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

# --- 2. recuperation des fichiers ------------------------------------------
if ($Source) {
    if (-not (Test-Path $Source)) {
        throw "Dossier source introuvable : $Source"
    }
    Write-Line "  [2/4] Copie depuis : $Source" 'Gray'
    foreach ($f in $Files) {
        $src  = Join-Path $Source $f
        $dest = Join-Path $Target $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dest -Force
            Write-Line "        [+] $f" 'Green'
        } else {
            Write-Line "        [=] $f absent de la source, ignore" 'DarkGray'
        }
    }
    if (-not (Test-Path (Join-Path $Target 'xozhub.ps1'))) {
        throw "xozhub.ps1 est introuvable dans $Source : rien n'a ete copie."
    }
} else {
    Write-Line '  [2/4] Telechargement depuis GitHub...' 'Gray'
    foreach ($f in $Files) {
        $url  = "$RepoRaw/$f"
        $dest = Join-Path $Target $f
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
            Write-Line "        [+] $f" 'Green'
        } catch {
            Write-Line "        [X] echec pour $f" 'Red'
            Write-Line "            $($_.Exception.Message)" 'DarkGray'
            Write-Line ''
            Write-Line '  Verifie que le depot GitHub "XozHub" existe bien et est public,' 'Yellow'
            Write-Line '  puis reessaie. URL testee :' 'DarkGray'
            Write-Line "    $url" 'DarkGray'
            Write-Line ''
            Write-Line '  Alternative sans internet : utilise install-local.bat' 'Cyan'
            throw
        }
    }
}

# --- 3. PATH utilisateur ---------------------------------------------------
Write-Line '  [3/4] Configuration du PATH...' 'Gray'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $userPath) { $userPath = '' }
$parts = @($userPath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })

if ($parts -notcontains $Target) {
    $newPath = (@($parts) + $Target) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Line "        [+] $Target ajoute au PATH utilisateur" 'Green'
} else {
    Write-Line '        [=] deja present dans le PATH' 'DarkGray'
}
$env:Path = "$env:Path;$Target"

# --- 4. verification -------------------------------------------------------
Write-Line '  [4/4] Verification...' 'Gray'
$xps  = Join-Path $Target 'xozhub.ps1'
$xbat = Join-Path $Target 'xozhub.bat'
if (-not (Test-Path $xps))  { throw 'xozhub.ps1 est manquant apres installation.' }
if (-not (Test-Path $xbat)) { throw 'xozhub.bat est manquant apres installation.' }
Write-Line "        [+] xozhub.ps1  ($((Get-Item $xps).Length) octets)" 'Green'
Write-Line "        [+] xozhub.bat  ($((Get-Item $xbat).Length) octets)" 'Green'

Write-Host ''
Write-Line '   +=======================================================+' 'Magenta'
Write-Line '   |   TERMINE !                                           |' 'Green'
Write-Line '   +=======================================================+' 'Magenta'
Write-Host ''
Write-Line '   Ferme cette fenetre, ouvre un NOUVEAU cmd, puis tape :' 'White'
Write-Host ''
Write-Line '        xozhub' 'Cyan'
Write-Host ''
Write-Line '   Configuration de la cle API (exemple Groq) :' 'DarkGray'
Write-Line '        xozhub setup --key gsk_ta_cle_ici' 'DarkGray'
Write-Host ''
