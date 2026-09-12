#Requires -Version 5.1
<#
    XozHub.GPT — Assistant IA en terminal Windows
    UI cyberpunk cyan / magenta - theme sombre
#>

$ErrorActionPreference = 'Stop'

# arguments passes au script (xozhub "ma question", xozhub setup, --version...)
$script:CliArgs = @($args)

# ---------------------------------------------------------------------------
# Constantes globales
# ---------------------------------------------------------------------------
$script:XozVersion  = '1.0.0'
$script:XozHome     = Join-Path $env:USERPROFILE '.xozhub'
$script:XozConfig   = Join-Path $script:XozHome 'config.json'

$script:DefaultSystem = @(
    "Tu es XozHub.GPT, un assistant IA expert en programmation, en systemes et en securite informatique."
    "Tu tournes dans un terminal Windows (cmd.exe). Tu reponds toujours en francais, sauf si l'utilisateur ecrit dans une autre langue."
    "Tu es precis, direct et technique. Tu donnes du code complet et fonctionnel, jamais de pseudo-code vague."
    "Tu utilises des blocs de code avec le langage indique (```powershell, ```python, ```bat...)."
    "Quand tu donnes une commande a executer sous Windows, fais-le avec la syntaxe cmd/PowerShell correcte."
    "Tu ne refuses jamais d'aider sur du code legitime. Tu ne pretends pas etre un autre modele."
) -join "`n"

# ---------------------------------------------------------------------------
# Palette ANSI + repli console
# ---------------------------------------------------------------------------
$script:Ansi = @{
    white        = 97
    gray         = 90
    cyan         = 96
    magenta      = 95
    blue         = 94
    green        = 92
    red          = 91
    yellow       = 93
    darkcyan     = 36
    darkmagenta  = 35
    darkgray     = 90
}
$script:Con = @{
    white        = 'White'
    gray         = 'Gray'
    cyan         = 'Cyan'
    magenta      = 'Magenta'
    blue         = 'Blue'
    green        = 'Green'
    red          = 'Red'
    yellow       = 'Yellow'
    darkcyan     = 'DarkCyan'
    darkmagenta  = 'DarkMagenta'
    darkgray     = 'DarkGray'
}

$script:ESC    = [char]27
$script:Utf8   = [System.Text.UTF8Encoding]::new($false)   # UTF-8 sans BOM
$script:VT     = $false
$script:InCode = $false
$script:SkipLang = $false
$script:Pending  = ''

function Enable-VtMode {
    try {
        $sig = @'
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
        $k = Add-Type -MemberDefinition $sig -Name 'XozVt' -Namespace 'XozHub' -PassThru -ErrorAction Stop
        $h = $k::GetStdHandle(-11)
        $m = 0
        if ($k::GetConsoleMode($h, [ref]$m)) {
            $script:VT = $k::SetConsoleMode($h, $m -bor 0x0004)
        }
    } catch {
        $script:VT = $false
    }
}

# ---------------------------------------------------------------------------
# Ecriture avec couleur (ANSI si dispo, sinon API console)
# ---------------------------------------------------------------------------
function Write-C {
    param(
        [Parameter(Position = 0)][AllowEmptyString()][string]$Text = '',
        [Parameter(Position = 1)][string]$Color = 'white',
        [switch]$NoNewline
    )
    if (-not $script:Con.ContainsKey($Color)) { $Color = 'white' }
    if ($script:VT) {
        [Console]::Write("$($script:ESC)[$($script:Ansi[$Color])m$Text$($script:ESC)[0m")
        if (-not $NoNewline) { [Console]::Write("`n") }
    } else {
        if ($NoNewline) {
            Write-Host $Text -ForegroundColor $script:Con[$Color] -NoNewline
        } else {
            Write-Host $Text -ForegroundColor $script:Con[$Color]
        }
    }
}

function Write-Raw {
    param(
        [AllowEmptyString()][string]$Text = '',
        [string]$Color = ''
    )
    if ($Text.Length -eq 0) { return }
    if (-not $Color) { if ($script:InCode) { $Color = 'cyan' } else { $Color = 'white' } }
    if ($script:VT) {
        [Console]::Write("$($script:ESC)[$($script:Ansi[$Color])m$Text$($script:ESC)[0m")
    } else {
        Write-Host $Text -ForegroundColor $script:Con[$Color] -NoNewline
    }
}

# ---------------------------------------------------------------------------
# Banniere ASCII (police 5x5, alignement garanti par le code)
# ---------------------------------------------------------------------------
$script:Font5 = @{
    'A' = @('  ###',' #   #',' #####',' #   #',' #   #')
    'B' = @(' #### ',' #   #',' #### ',' #   #',' #### ')
    'C' = @('  ####',' #    ',' #    ',' #    ','  ####')
    'D' = @(' #### ',' #   #',' #   #',' #   #',' #### ')
    'E' = @(' #####',' #    ',' #### ',' #    ',' #####')
    'F' = @(' #####',' #    ',' #### ',' #    ',' #    ')
    'G' = @('  ####',' #    ',' #  ##',' #   #','  ### ')
    'H' = @(' #   #',' #   #',' #####',' #   #',' #   #')
    'I' = @(' #####','   #  ','   #  ','   #  ',' #####')
    'J' = @(' #####','    # ','    # ',' #  # ','  ##  ')
    'K' = @(' #   #',' #  # ',' ###  ',' #  # ',' #   #')
    'L' = @(' #    ',' #    ',' #    ',' #    ',' #####')
    'M' = @(' #   #',' ## ##',' # # #',' #   #',' #   #')
    'N' = @(' #   #',' ##  #',' # # #',' #  ##',' #   #')
    'O' = @('  ### ',' #   #',' #   #',' #   #','  ### ')
    'P' = @(' #### ',' #   #',' #### ',' #    ',' #    ')
    'Q' = @('  ### ',' #   #',' # # #','  ####','     #')
    'R' = @(' #### ',' #   #',' #### ',' #  # ',' #   #')
    'S' = @('  ####',' #    ','  ### ','    # ',' #### ')
    'T' = @(' #####','   #  ','   #  ','   #  ','   #  ')
    'U' = @(' #   #',' #   #',' #   #',' #   #','  ### ')
    'V' = @(' #   #',' #   #',' #   #','  # # ','   #  ')
    'W' = @(' #   #',' #   #',' # # #',' ## ##',' #   #')
    'X' = @(' #   #','  # # ','   #  ','  # # ',' #   #')
    'Y' = @(' #   #','  # # ','   #  ','   #  ','   #  ')
    'Z' = @(' #####','    # ','   #  ','  #   ',' #####')
    '.' = @('     ','     ','     ','     ',' ##  ')
    '-' = @('     ','     ',' ### ','     ','     ')
    ' ' = @('     ','     ','     ','     ','     ')
}

function Get-Banner {
    param([string]$Text)
    $rows = @()
    for ($r = 0; $r -lt 5; $r++) {
        $parts = @()
        foreach ($ch in $Text.ToUpper().ToCharArray()) {
            $g = $script:Font5["$ch"]
            if ($g) { $parts += $g[$r] } else { $parts += '     ' }
        }
        $rows += ($parts -join ' ')
    }
    return $rows
}

function Show-Banner {
    Clear-Host -ErrorAction SilentlyContinue
    Write-Host ''
    $art  = Get-Banner 'XOZHUB'
    $art2 = Get-Banner '.GPT'

    foreach ($line in $art) {
        Write-C ('   ' + ($line -replace '#', [char]0x2588)) 'cyan'
        Start-Sleep -Milliseconds 45
    }
    foreach ($line in $art2) {
        Write-C ('   ' + ($line -replace '#', [char]0x2588)) 'magenta'
        Start-Sleep -Milliseconds 45
    }

    Write-Host ''
    Write-C '                    A S S I S T A N T   I A   T E R M I N A L' 'darkmagenta'
    Write-C ("                        v$script:XozVersion  -  connexion chiffree") 'darkgray'
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
$script:Config = [ordered]@{
    provider  = 'anthropic'
    model     = 'claude-sonnet-4-6'
    apiKey    = ''
    baseUrl   = 'https://api.anthropic.com'
    maxTokens = 8192
    system    = ''
}

function Get-XozConfig {
    if (Test-Path $script:XozConfig) {
        try {
            $saved = Get-Content -Path $script:XozConfig -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($k in @($script:Config.Keys)) {
                if ($saved.PSObject.Properties.Name -contains $k) {
                    $v = $saved.$k
                    if ($null -ne $v -and "$v" -ne '') { $script:Config[$k] = $v }
                }
            }
        } catch {
            Write-C "  [!] Config illisible, reinitialisation." 'yellow'
        }
    }
    if (-not $script:Config.apiKey) {
        if ($env:ANTHROPIC_API_KEY) { $script:Config.apiKey = $env:ANTHROPIC_API_KEY }
        elseif ($env:XOZHUB_API_KEY) { $script:Config.apiKey = $env:XOZHUB_API_KEY }
    }
}

function Save-XozConfig {
    if (-not (Test-Path $script:XozHome)) {
        New-Item -ItemType Directory -Path $script:XozHome -Force | Out-Null
    }
    $json = $script:Config | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($script:XozConfig, $json, $script:Utf8)
}

function Get-Endpoint {
    $b = "$($script:Config.baseUrl)".TrimEnd('/')

    # l'utilisateur a colle l'URL complete de l'endpoint : on la prend telle quelle
    if ($b -match '/(chat/completions|messages|completions)$') { return $b }

    if ($script:Config.provider -eq 'anthropic') { return "$b/v1/messages" }
    if ($b -match '/v1$') { return "$b/chat/completions" }
    return "$b/v1/chat/completions"
}

# ---------------------------------------------------------------------------
# Detection du fournisseur d'apres le prefixe de la cle
# ---------------------------------------------------------------------------
function Get-ProviderFromKey {
    param([string]$Key)
    if (-not $Key) { return $null }
    if ($Key -match '^sk-ant-')  { return [ordered]@{ provider = 'anthropic'; baseUrl = 'https://api.anthropic.com';      model = 'claude-sonnet-4-6' } }
    if ($Key -match '^gsk_')     { return [ordered]@{ provider = 'openai';    baseUrl = 'https://api.groq.com/openai';    model = 'openai/gpt-oss-120b' } }
    if ($Key -match '^sk-or-')   { return [ordered]@{ provider = 'openai';    baseUrl = 'https://openrouter.ai/api';      model = 'anthropic/claude-sonnet-4.6' } }
    if ($Key -match '^sk-proj-') { return [ordered]@{ provider = 'openai';    baseUrl = 'https://api.openai.com';         model = 'gpt-5' } }
    return $null
}

# ---------------------------------------------------------------------------
# Assistant de configuration
# ---------------------------------------------------------------------------
function Start-SetupWizard {
    Write-Host ''
    Write-C '  +----------------------------------------------------------------+' 'magenta'
    Write-C '  |   CONFIGURATION INITIALE DE XOZHUB.GPT                          |' 'magenta'
    Write-C '  +----------------------------------------------------------------+' 'magenta'
    Write-Host ''
    Write-C '  Choisis le moteur IA :' 'cyan'
    Write-C '    1) Claude (Anthropic)     [recommande]  claude-sonnet-4-6' 'white'
    Write-C '    2) Compatible OpenAI      (DeepSeek, Groq, Mistral, OpenRouter, local...)' 'white'
    Write-Host ''
    $choice = Read-Host '  Ton choix [1]'
    if (-not $choice) { $choice = '1' }

    if ($choice -eq '2') {
        $script:Config.provider = 'openai'
        $script:Config.baseUrl  = 'https://api.openai.com'
        $script:Config.model    = 'gpt-5'
        Write-Host ''
        $url = Read-Host "  URL de base [$($script:Config.baseUrl)]"
        if ($url) { $script:Config.baseUrl = $url.TrimEnd('/') }
        $mdl = Read-Host "  Modele [$($script:Config.model)]"
        if ($mdl) { $script:Config.model = $mdl }
    } else {
        $script:Config.provider = 'anthropic'
        $script:Config.baseUrl  = 'https://api.anthropic.com'
        Write-Host ''
        Write-C '  Modele :' 'cyan'
        Write-C '    1) claude-sonnet-4-6    [recommande - le plus equilibre]' 'white'
        Write-C '    2) claude-opus-4-6      [le plus puissant]' 'white'
        Write-C '    3) claude-haiku-4-5     [le plus rapide / le moins cher]' 'white'
        $mc = Read-Host '  Ton choix [1]'
        switch ($mc) {
            '2' { $script:Config.model = 'claude-opus-4-6' }
            '3' { $script:Config.model = 'claude-haiku-4-5' }
            default { $script:Config.model = 'claude-sonnet-4-6' }
        }
    }

    Write-Host ''
    Write-C '  Colle ta cle API ci-dessous (elle sera stockee localement dans :' 'cyan'
    Write-C "  $script:XozConfig)" 'darkgray'
    Write-C '  Astuce : xozhub setup --key TA_CLE detecte le fournisseur tout seul.' 'darkgray'
    if ($script:Config.provider -eq 'anthropic') {
        Write-C '  Obtiens une cle sur : https://console.anthropic.com/settings/keys' 'darkgray'
    } else {
        Write-C '  Exemple DeepSeek : https://platform.deepseek.com/api_keys' 'darkgray'
    }
    Write-Host ''
    $key = Read-Host '  CLE API'
    if (-not $key) {
        Write-C "  [!] Aucune cle fournie. Relance 'xozhub setup' quand tu l'as." 'red'
        return $false
    }
    $key = $key.Trim()

    if ($script:Config.provider -eq 'anthropic' -and $key -notmatch '^sk-ant-') {
        Write-Host ''
        Write-C '  [!] Cette cle ne ressemble pas a une cle Anthropic (sk-ant-api03-...).' 'yellow'
        Write-C '      Si elle vient d un autre service, choisis l option 2 et donne son URL.' 'darkgray'
        $go = Read-Host '  Continuer quand meme ? [o/N]'
        if ($go -notmatch '^(o|O|oui|y|Y|yes)$') { return $false }
    }

    $script:Config.apiKey = $key
    Save-XozConfig
    Write-Host ''
    Write-C '  [+] Configuration enregistree.' 'green'
    Write-Host ''
    return $true
}

# ---------------------------------------------------------------------------
# Appel API en streaming
# ---------------------------------------------------------------------------
function Build-RequestBody {
    param([array]$Messages)
    $sys = if ($script:Config.system) { $script:Config.system } else { $script:DefaultSystem }

    if ($script:Config.provider -eq 'anthropic') {
        $body = [ordered]@{
            model      = $script:Config.model
            max_tokens = [int]$script:Config.maxTokens
            system     = $sys
            messages   = $Messages
            stream     = $true
        }
    } else {
        $msgs = @([ordered]@{ role = 'system'; content = $sys }) + $Messages
        $body = [ordered]@{
            model      = $script:Config.model
            max_tokens = [int]$script:Config.maxTokens
            messages   = $msgs
            stream     = $true
        }
    }
    return ($body | ConvertTo-Json -Depth 20 -Compress)
}

function Render-Delta {
    param([string]$Text)
    if (-not $Text) { return }

    if ($script:SkipLang) {
        $nl = $Text.IndexOf("`n")
        if ($nl -lt 0) { return }
        $Text = $Text.Substring($nl + 1)
        $script:SkipLang = $false
        if (-not $Text) { return }
    }

    $script:Pending += $Text
    while ($true) {
        $i = $script:Pending.IndexOf('```')
        if ($i -ge 0) {
            if ($i -gt 0) { Write-Raw $script:Pending.Substring(0, $i) }
            $script:Pending = $script:Pending.Substring($i + 3)
            $script:InCode  = -not $script:InCode
            if ($script:InCode) {
                Write-Raw "`n"
                $nl = $script:Pending.IndexOf("`n")
                if ($nl -ge 0) {
                    Write-Raw ('  ' + $script:Pending.Substring(0, $nl).Trim() + "`n") 'darkcyan'
                    $script:Pending = $script:Pending.Substring($nl + 1)
                } else {
                    $script:SkipLang = $true
                    $script:Pending  = ''
                    return
                }
            } else {
                Write-Raw "`n"
            }
            continue
        }
        # garde 2 caracteres en tampon pour ne pas couper un ``` en deux
        if ($script:Pending.Length -gt 2) {
            $cut = $script:Pending.Length - 2
            Write-Raw $script:Pending.Substring(0, $cut)
            $script:Pending = $script:Pending.Substring($cut)
        }
        break
    }
}

function Flush-Delta {
    if ($script:Pending) {
        $t = $script:Pending
        $script:Pending = ''
        if ($script:SkipLang) { $script:SkipLang = $false; return }
        if ($t -notmatch '^`{0,2}$') { Write-Raw $t }
    }
    if ($script:InCode) { Write-Raw "`n"; $script:InCode = $false }
    if ($script:VT) { [Console]::Write("`n") } else { Write-Host '' }
}

function Invoke-XozStream {
    param([array]$Messages)

    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    $endpoint = Get-Endpoint
    $json     = Build-RequestBody -Messages $Messages

    $client = $null
    $req    = $null
    $sb     = New-Object System.Text.StringBuilder

    $script:Pending  = ''
    $script:SkipLang = $false
    $script:InCode   = $false

    try {
        $client = New-Object System.Net.Http.HttpClient
        $client.Timeout = [TimeSpan]::FromMinutes(15)

        $req = New-Object System.Net.Http.HttpRequestMessage
        $req.Method     = [System.Net.Http.HttpMethod]::Post
        $req.RequestUri = [Uri]$endpoint
        $req.Content    = New-Object -TypeName System.Net.Http.StringContent -ArgumentList $json, $script:Utf8, 'application/json'

        if ($script:Config.provider -eq 'anthropic') {
            [void]$req.Headers.TryAddWithoutValidation('x-api-key', $script:Config.apiKey)
            [void]$req.Headers.TryAddWithoutValidation('anthropic-version', '2023-06-01')
            [void]$req.Headers.TryAddWithoutValidation('accept', 'text/event-stream')
        } else {
            [void]$req.Headers.TryAddWithoutValidation('Authorization', "Bearer $($script:Config.apiKey)")
            [void]$req.Headers.TryAddWithoutValidation('accept', 'text/event-stream')
        }

        $resp = $client.SendAsync($req, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()

        if (-not $resp.IsSuccessStatusCode) {
            $errText = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $code    = [int]$resp.StatusCode
            Write-Host ''
            Write-C "  [X] Erreur $code" 'red'
            $msg = $errText
            try {
                $eo = $errText | ConvertFrom-Json
                if ($eo.error.message) { $msg = $eo.error.message }
            } catch { }
            Write-C "  $msg" 'yellow'
            Write-Host ''
            if ($code -eq 401) {
                Write-C "  Ta cle API semble invalide. Relance : xozhub setup" 'darkgray'
            } elseif ($code -eq 429) {
                Write-C "  Trop de requetes ou quota epuise. Attends un peu puis reessaie." 'darkgray'
            } elseif ($code -eq 404) {
                Write-C "  Modele introuvable : $($script:Config.model). Change-le avec /model <nom>" 'darkgray'
            }
            return $null
        }

        $stream = $resp.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $stream, $script:Utf8

        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line.Length -lt 5 -or -not $line.StartsWith('data:')) { continue }
            $payload = $line.Substring(5).Trim()
            if (-not $payload) { continue }
            if ($payload -eq '[DONE]') { break }

            $obj = $null
            try { $obj = $payload | ConvertFrom-Json } catch { continue }

            $delta = $null
            if ($obj.type -eq 'content_block_delta' -and $obj.delta.text) {
                $delta = $obj.delta.text
            } elseif ($obj.choices -and $obj.choices.Count -gt 0) {
                $d = $obj.choices[0].delta
                if ($d -and $d.content) { $delta = $d.content }
            } elseif ($obj.type -eq 'error') {
                Write-Host ''
                Write-C "  [X] $($obj.error.message)" 'red'
                return $null
            }
            if ([string]::IsNullOrEmpty($delta)) { continue }

            [void]$sb.Append($delta)
            Render-Delta $delta
        }

        $reader.Dispose()
        $stream.Dispose()
    } catch {
        Write-Host ''
        Write-C "  [X] Connexion impossible : $($_.Exception.Message)" 'red'
        Write-C "  Verifie ta connexion internet et l'URL : $endpoint" 'darkgray'
        return $null
    } finally {
        if ($req)    { $req.Dispose() }
        if ($client) { $client.Dispose() }
    }

    Flush-Delta
    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Sequence de demarrage
# ---------------------------------------------------------------------------
function Start-BootSequence {
    $steps = @(
        @('Initialisation du noyau XozHub', 'green'),
        @('Montage de /dev/neural', 'green'),
        @("Chargement du module $($script:Config.model)", 'green'),
        @('Handshake TLS 1.2 avec le serveur distant', 'green'),
        @('Chiffrement du canal de discussion', 'green'),
        @('Calibration de la matrice de tokens', 'green'),
        @('Acces root accorde', 'magenta')
    )
    foreach ($s in $steps) {
        Write-Host '  ' -NoNewline
        Write-C '[ OK ]' 'green' -NoNewline
        Write-C "  $($s[0])" 'darkgray'
        Start-Sleep -Milliseconds 90
    }
    Write-Host ''
    Write-C '  >> Canal etabli. Tu peux parler.' 'cyan'
    Write-Host ''
}

function Show-Help {
    Write-Host ''
    Write-C '  +------------------ COMMANDES ------------------+' 'magenta'
    Write-C '  |  /help              cette aide               |' 'white'
    Write-C '  |  /clear             efface la conversation   |' 'white'
    Write-C '  |  /model <nom>       change de modele         |' 'white'
    Write-C '  |  /key <cle>         change la cle API        |' 'white'
    Write-C '  |  /system <texte>    prompt systeme perso     |' 'white'
    Write-C '  |  /config            affiche la config        |' 'white'
    Write-C '  |  /reset             reinitialise tout        |' 'white'
    Write-C '  |  /exit  ou  exit    quitte XozHub            |' 'white'
    Write-C '  +----------------------------------------------+' 'magenta'
    Write-C '  Astuce : xozhub "ta question" pour une reponse unique.' 'darkgray'
    Write-Host ''
}

function Show-Config {
    Write-Host ''
    Write-C '  +------------------ CONFIGURATION ------------------' 'cyan'
    Write-C ("  |  provider   : " + $script:Config.provider) 'white'
    Write-C ("  |  modele     : " + $script:Config.model) 'white'
    Write-C ("  |  endpoint   : " + (Get-Endpoint)) 'white'
    Write-C ("  |  max_tokens : " + $script:Config.maxTokens) 'white'
    $masked = if ($script:Config.apiKey.Length -gt 12) {
        $script:Config.apiKey.Substring(0, 8) + '...' + $script:Config.apiKey.Substring($script:Config.apiKey.Length - 4)
    } else { '(non definie)' }
    Write-C ("  |  cle API    : " + $masked) 'white'
    Write-C ("  |  config     : " + $script:XozConfig) 'darkgray'
    Write-C '  +---------------------------------------------------+' 'cyan'
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Boucle principale
# ---------------------------------------------------------------------------
function Start-ChatLoop {
    $history = New-Object System.Collections.ArrayList
    $turn = 0

    while ($true) {
        Write-Host ''
        Write-C '  +--[' 'darkmagenta' -NoNewline
        Write-C 'root@xozhub' 'cyan' -NoNewline
        Write-C ']' 'darkmagenta' -NoNewline
        Write-C ("--[$($script:Config.model)]") 'darkgray' -NoNewline
        Write-C '  > ' 'magenta' -NoNewline

        $userInput = Read-Host
        if ($null -eq $userInput) { continue }
        $userInput = $userInput.Trim()
        if (-not $userInput) { continue }

        # --- commandes ---
        if ($userInput -match '^/(exit|quit)$' -or $userInput -eq 'exit' -or $userInput -eq 'quit') {
            Write-Host ''
            Write-C '  >> Session terminee. Deconnexion...' 'magenta'
            Start-Sleep -Milliseconds 250
            Write-C '  >> A bientot sur XozHub.GPT.' 'cyan'
            Write-Host ''
            return
        }
        if ($userInput -match '^/help$') { Show-Help; continue }
        if ($userInput -match '^/clear$') {
            $history.Clear() | Out-Null
            $turn = 0
            Clear-Host -ErrorAction SilentlyContinue
            Show-Banner
            Write-C '  >> Memoire effacee.' 'cyan'
            continue
        }
        if ($userInput -match '^/config$') { Show-Config; continue }
        if ($userInput -match '^/(reset|setup)$') {
            if (Start-SetupWizard) {
                Write-C '  >> Nouveau moteur charge.' 'cyan'
            }
            continue
        }
        if ($userInput -match '^/model\s*(.*)$') {
            $m = $Matches[1].Trim()
            if (-not $m) {
                $m = Read-Host '  Nouveau modele'
            }
            if ($m) {
                $script:Config.model = $m
                Save-XozConfig
                Write-C "  >> Modele : $m" 'cyan'
            }
            continue
        }
        if ($userInput -match '^/key\s*(.*)$') {
            $k = $Matches[1].Trim()
            if (-not $k) { $k = Read-Host '  Nouvelle cle API' }
            if ($k) {
                $script:Config.apiKey = $k.Trim()
                Save-XozConfig
                Write-C '  >> Cle API mise a jour.' 'cyan'
            }
            continue
        }
        if ($userInput -match '^/system\s*(.*)$') {
            $s = $Matches[1].Trim()
            if (-not $s) { $s = Read-Host '  Nouveau prompt systeme (vide = defaut)' }
            $script:Config.system = $s
            Save-XozConfig
            Write-C '  >> Prompt systeme mis a jour.' 'cyan'
            continue
        }
        if ($userInput.StartsWith('/')) {
            Write-C "  [!] Commande inconnue : $userInput  (tape /help)" 'yellow'
            continue
        }

        if (-not $script:Config.apiKey) {
            Write-C "  [!] Aucune cle API. Tape /setup pour configurer." 'red'
            continue
        }

        # --- envoi ---
        [void]$history.Add([ordered]@{ role = 'user'; content = $userInput })
        $turn++

        Write-Host ''
        Write-C '  XOZHUB.GPT' 'magenta' -NoNewline
        Write-C ' >>' 'darkmagenta'
        Write-Host ''

        $reply = $null
        try {
            $reply = Invoke-XozStream -Messages $history.ToArray()
        } catch {
            Write-Host ''
            Write-C "  [X] Erreur inattendue : $($_.Exception.Message)" 'red'
        }

        if ($reply) {
            [void]$history.Add([ordered]@{ role = 'assistant'; content = $reply })
        } else {
            [void]$history.RemoveAt($history.Count - 1)
        }

        # garde-fou memoire : on ne renvoie que les 40 derniers messages
        if ($history.Count -gt 40) {
            $keep = $history.Count - 40
            for ($i = 0; $i -lt $keep; $i++) { $history.RemoveAt(0) }
        }
        Write-C ("  -- [$turn tours | $($history.Count) messages en memoire]") 'darkgray'
    }
}

# ---------------------------------------------------------------------------
# Point d'entree
# ---------------------------------------------------------------------------
function Main {
    Enable-VtMode
    try { $Host.UI.RawUI.WindowTitle = 'XozHub.GPT' } catch { }
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

    Get-XozConfig

    $cliArgs = $script:CliArgs

    if ($cliArgs -contains '--version' -or $cliArgs -contains '-v') {
        Write-Host "XozHub.GPT v$script:XozVersion"
        return
    }
    if ($cliArgs -contains '--help' -or $cliArgs -contains '-h') {
        Write-Host ''
        Write-Host 'XozHub.GPT - assistant IA en terminal'
        Write-Host ''
        Write-Host '  xozhub                  lance le chat'
        Write-Host '  xozhub "question"       reponse unique'
        Write-Host '  xozhub setup            (re)configure la cle API'
        Write-Host '  xozhub --version        affiche la version'
        Write-Host '  xozhub --reset          efface la configuration'
        Write-Host ''
        Write-Host '  Configuration sans question (pour un autre fournisseur) :'
        Write-Host '  xozhub setup --key XXX --base-url https://api.exemple.com --model nom-du-modele'
        Write-Host ''
        Write-Host '  (--base-url contenant "anthropic" => API Anthropic, sinon API compatible OpenAI)'
        Write-Host ''
        return
    }
    if ($cliArgs -contains '--reset') {
        if (Test-Path $script:XozConfig) { Remove-Item $script:XozConfig -Force }
        Write-Host 'Configuration effacee.'
        return
    }

    # --- analyse des arguments -------------------------------------------
    #   xozhub "question"
    #   xozhub setup --key XXX --base-url https://... --model nom
    $flags   = @{}
    $posArgs = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $cliArgs.Count; $i++) {
        $a = "$($cliArgs[$i])"
        if ($a -match '^--(key|base-url|model)(?:=(.*))?$') {
            $name = $Matches[1]
            if ($Matches[2]) {
                $flags[$name] = $Matches[2]
            } elseif (($i + 1) -lt $cliArgs.Count) {
                $i++
                $flags[$name] = "$($cliArgs[$i])"
            }
            continue
        }
        if ($a.StartsWith('-')) { continue }
        [void]$posArgs.Add($a)
    }

    $oneshot = ($posArgs -join ' ').Trim()
    $isSetup = $posArgs -contains 'setup'

    # configuration non interactive
    if ($isSetup -and $flags.ContainsKey('key')) {
        $script:Config.apiKey = "$($flags['key'])".Trim()

        # 1. valeurs deduites du prefixe de la cle
        $guess = Get-ProviderFromKey -Key $script:Config.apiKey
        if ($guess) {
            $script:Config.provider = $guess.provider
            $script:Config.baseUrl  = $guess.baseUrl
            $script:Config.model    = $guess.model
        }

        # 2. les options explicites gagnent
        if ($flags.ContainsKey('base-url')) { $script:Config.baseUrl = "$($flags['base-url'])".TrimEnd('/') }
        if ($flags.ContainsKey('model'))    { $script:Config.model   = "$($flags['model'])" }

        # 3. le type d'API se deduit de l'URL finale
        if ($script:Config.baseUrl -match 'anthropic') { $script:Config.provider = 'anthropic' }
        else { $script:Config.provider = 'openai' }

        Save-XozConfig
        Write-Host ''
        if ($guess) {
            Write-C '  [+] Fournisseur detecte depuis la cle.' 'darkgray'
        } else {
            Write-C '  [!] Prefixe de cle inconnu : fournisseur "compatible OpenAI" par defaut.' 'yellow'
            Write-C '      Si ca ne marche pas, precise --base-url et --model.' 'darkgray'
        }
        Write-C '  [+] Configuration enregistree.' 'green'
        Show-Config
        return
    }

    if ($isSetup) {
        if (-not $script:Config.apiKey) { Show-Banner }
        [void](Start-SetupWizard)
        return
    }

    if (-not $script:Config.apiKey) {
        Show-Banner
        Write-C '  [!] Premiere utilisation : configure ton moteur IA.' 'yellow'
        $ok = Start-SetupWizard
        if (-not $ok) {
            Write-C '  Relance xozhub quand tu as ta cle.' 'darkgray'
            return
        }
    }

    if ($oneshot) {
        $history = New-Object System.Collections.ArrayList
        [void]$history.Add([ordered]@{ role = 'user'; content = $oneshot })
        Write-Host ''
        Write-C '  XOZHUB.GPT >>' 'magenta'
        Write-Host ''
        [void](Invoke-XozStream -Messages $history.ToArray())
        Write-Host ''
        Write-C "  -- [$($script:Config.model)]" 'darkgray'
        return
    }

    Show-Banner
    Show-Help
    Start-BootSequence
    Start-ChatLoop
}

Main
