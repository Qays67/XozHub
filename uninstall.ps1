#Requires -Version 5.1
<#
    XozHub.GPT - desinstalleur
    Retire le dossier d'installation et nettoie le PATH utilisateur.
    La configuration (%USERPROFILE%\.xozhub) est conservee par defaut.
#>
$ErrorActionPreference = 'Stop'

$Target = Join-Path $env:USERPROFILE 'XozHub'
$Config = Join-Path $env:USERPROFILE '.xozhub'

function Write-Line {
    param([string]$T = '', [string]$C = 'Gray')
    Write-Host $T -ForegroundColor $C
}

Write-Host ''
Write-Line '   X O Z H U B . G P T   -   D E S I N S T A L L A T I O N' 'Magenta'
Write-Host ''

# --- 1. retrait du PATH ----------------------------------------------------
Write-Line '  [1/3] Nettoyage du PATH utilisateur...' 'Gray'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $userPath) { $userPath = '' }
$parts   = @($userPath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })
$filtered = @($parts | Where-Object { $_.TrimEnd('\') -ne $Target.TrimEnd('\') })

if ($filtered.Count -ne $parts.Count) {
    [Environment]::SetEnvironmentVariable('Path', ($filtered -join ';'), 'User')
    Write-Line "        [+] $Target retire du PATH" 'Green'
} else {
    Write-Line '        [=] rien a retirer' 'DarkGray'
}

# --- 2. suppression des fichiers -------------------------------------------
Write-Line '  [2/3] Suppression des fichiers...' 'Gray'
if (Test-Path $Target) {
    try {
        Remove-Item -Path $Target -Recurse -Force -ErrorAction Stop
        Write-Line "        [+] $Target supprime" 'Green'
    } catch {
        Write-Line "        [X] $($_.Exception.Message)" 'Red'
        Write-Line '            Ferme toutes les fenetres XozHub puis relance.' 'Yellow'
    }
} else {
    Write-Line '        [=] dossier deja absent' 'DarkGray'
}

# --- 3. configuration ------------------------------------------------------
Write-Line '  [3/3] Configuration utilisateur...' 'Gray'
if (Test-Path $Config) {
    Write-Line "        [i] Trouve : $Config" 'Yellow'
    $ans = Read-Host '        Supprimer aussi la configuration (cle API incluse) ? [o/N]'
    if ($ans -match '^(o|O|oui|y|Y|yes)$') {
        try {
            Remove-Item -Path $Config -Recurse -Force -ErrorAction Stop
            Write-Line '        [+] configuration supprimee' 'Green'
        } catch {
            Write-Line "        [X] $($_.Exception.Message)" 'Red'
        }
    } else {
        Write-Line '        [=] configuration conservee' 'DarkGray'
    }
} else {
    Write-Line '        [=] aucune configuration trouvee' 'DarkGray'
}

Write-Host ''
Write-Line '   Desinstallation terminee. Ouvre un nouveau cmd.' 'Cyan'
Write-Host ''
