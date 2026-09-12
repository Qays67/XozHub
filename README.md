# XozHub.GPT

**Assistant IA pour l'invite de commandes Windows.** Interface terminal style *hacker*
(cyan / magenta), réponses en streaming, zéro dépendance (batch + PowerShell natifs).

> XozHub.GPT est le **client**. Le modèle tourne chez le fournisseur que tu choisis —
> par défaut **Claude Sonnet 4.6** (Anthropic). Il te faut donc une clé API.

---

## Installation

Ouvre une invite de commandes (`Win`, tape `cmd`, `Entrée`) puis colle :

```bat
curl -fsSL https://raw.githubusercontent.com/Qays67/XozHub/main/install.bat -o "%TEMP%\xozhub-install.bat" && "%TEMP%\xozhub-install.bat"
```

Alternative PowerShell :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Qays67/XozHub/main/install.ps1 | iex"
```

Ensuite : **ferme le cmd, rouvre-en un nouveau**, puis tape `xozhub`.

### Ce que fait l'installeur

1. télécharge les fichiers dans `%USERPROFILE%\XozHub`
2. ajoute ce dossier au **PATH utilisateur** (sans `setx`, donc pas de troncature à 1024 caractères)
3. vérifie que les fichiers sont bien présents

### Installation hors ligne (sans internet)

Utile si la commande ci-dessus répond `curl : (22) ... 404` (proxy, antivirus, GitHub
inaccessible) ou si tu as récupéré le dossier du projet en ZIP : les fichiers sont déjà là.
**Double-clique `install-local.bat`** : il fait exactement la même chose (copie + PATH)
sans passer par internet.

Ou en ligne de commande :

```bat
cd /d "C:\chemin\vers\le\projet"
install-local.bat
```

Ensuite : ouvre un **nouveau** cmd et tape `xozhub`.

---

## Premier lancement

Au premier `xozhub`, un assistant de configuration se lance :

| Étape | Choix |
|---|---|
| Moteur | `1` Claude (Anthropic) — recommandé · `2` toute API compatible OpenAI |
| Modèle | `claude-sonnet-4-6`, `claude-opus-4-6`, `claude-haiku-4-5` |
| Clé API | collée une seule fois, stockée dans `%USERPROFILE%\.xozhub\config.json` |

Clé Claude : <https://console.anthropic.com/settings/keys>

---

## Utilisation

```bat
xozhub                              :: lance le chat interactif
xozhub "ma question"                :: réponse unique puis fermeture
xozhub setup                        :: (re)configure moteur + clé
xozhub --version                    :: affiche la version
xozhub --reset                      :: efface la configuration
```

### Configurer un autre fournisseur sans passer par le menu

Utile quand ta clé ne vient pas d'Anthropic (préfixe inconnu, proxy maison, etc.) :

```bat
xozhub setup --key TA_CLE
```

Le fournisseur est déduit du préfixe de la clé :

| Préfixe | Fournisseur | URL de base | Modèle par défaut |
|---|---|---|---|
| `sk-ant-` | Anthropic | `https://api.anthropic.com` | `claude-sonnet-4-6` |
| `gsk_` | Groq | `https://api.groq.com/openai` | `openai/gpt-oss-120b` |
| `sk-or-` | OpenRouter | `https://openrouter.ai/api` | `anthropic/claude-sonnet-4.6` |
| `sk-proj-` | OpenAI | `https://api.openai.com` | `gpt-5` |
| autre | inconnu ⇒ compatible OpenAI | à préciser | à préciser |

Tu peux toujours forcer les valeurs :

```bat
xozhub setup --key TA_CLE --base-url https://api.exemple.com --model nom-du-modele
```

`--base-url` contenant « anthropic » ⇒ API Anthropic, sinon ⇒ API compatible OpenAI.
Si tu colles l'URL complète de l'endpoint (ex. `.../v1/chat/completions`), elle est
utilisée telle quelle.

### Commandes dans le chat

| Commande | Effet |
|---|---|
| `/help` | liste des commandes |
| `/clear` | efface la conversation en mémoire |
| `/model <nom>` | change de modèle à chaud |
| `/key <clé>` | change la clé API |
| `/system <texte>` | prompt système personnalisé |
| `/config` | affiche la configuration active |
| `/reset`, `/setup` | relance l'assistant de configuration |
| `/exit` | quitte |

L'historique est gardé **en mémoire uniquement** (40 derniers messages) et n'est jamais écrit sur disque.

---

## Utiliser un autre modèle

`/setup` → option **2**, puis renseigne l'URL de base et le nom du modèle :

| Fournisseur | URL de base | Modèle |
|---|---|---|
| DeepSeek | `https://api.deepseek.com` | `deepseek-chat` |
| Groq | `https://api.groq.com/openai` | `openai/gpt-oss-120b` |
| OpenRouter | `https://openrouter.ai/api` | `anthropic/claude-sonnet-4.6` |
| Mistral | `https://api.mistral.ai` | `mistral-large-latest` |
| OpenAI | `https://api.openai.com` | `gpt-5` |
| Local (Ollama) | `http://localhost:11434` | `llama3.2` |

---

## Désinstallation

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Qays67/XozHub/main/uninstall.ps1 | iex"
```

Retire le dossier `%USERPROFILE%\XozHub` et l'entrée du PATH. La configuration est conservée
sauf si tu réponds `o`.

---

## Publier le dépôt (pour que la commande d'installation marche)

La commande `curl ... install.bat` du site ne fonctionne **que** si le dépôt existe
en public sur GitHub. Tant qu'il n'existe pas, curl reçoit une erreur `404`.

### 1. Créer le compte GitHub

1. va sur <https://github.com/signup>
2. e-mail, mot de passe, nom d'utilisateur, puis valide le code reçu par e-mail
3. choisis l'offre **Free**

> ⚠️ Le nom d'utilisateur (pseudo) **n'accepte ni `_` ni espaces** : uniquement
> lettres, chiffres et tirets. Exemple valide : `Qays67`.
> Retiens-le, il apparaît dans toutes les URL.

### 2. Créer le dépôt

1. clique sur **+** (en haut à droite) → **New repository**
2. **Repository name** : `XozHub` (exactement, avec cette majuscule)
3. coche **Public** (indispensable : un dépôt privé renvoie 404 au téléchargement)
4. clique **Create repository**

### 3. Envoyer les fichiers

1. sur la page du dépôt vide, clique sur **uploading an existing file**
2. glisse-dépose ces 7 fichiers (pas de sous-dossier) :
   `index.html`, `install.bat`, `install.ps1`, `uninstall.bat`, `uninstall.ps1`,
   `xozhub.bat`, `xozhub.ps1`
3. en bas de page, clique **Commit changes**

Vérifie que la branche s'appelle bien `main` (c'est le défaut) : l'URL des fichiers
bruts est `https://raw.githubusercontent.com/<pseudo>/XozHub/main/<fichier>`.

### 4. Vérifier que les liens répondent

Tous les liens du site et des scripts pointent déjà vers le compte **`Qays67`** :

| Fichier | Où |
|---|---|
| `index.html` | 6 commandes affichées + lien GitHub du pied de page |
| `install.bat` / `uninstall.bat` | variable `REPO_RAW` |
| `install.ps1` | variable `$RepoRaw` |

Test rapide : ouvre dans un navigateur
`https://raw.githubusercontent.com/Qays67/XozHub/main/install.ps1` — tu dois voir le script.
Si tu vois `404: Not Found`, le dépôt est privé, mal nommé, ou pas encore créé.

> Si tu changes de pseudo ou de nom de dépôt plus tard, remplace `Qays67/XozHub` dans :
> `index.html` (constante `GH` du script + lien du pied de page), `install.bat`,
> `uninstall.bat` (`REPO_RAW`) et `install.ps1` (`$RepoRaw`).
> Ces valeurs ne servent que de **repli** : dès que la page est ouverte depuis un vrai
> site, les commandes utilisent son domaine (voir « Héberger sans GitHub »).

### 5. (Optionnel) Afficher le site avec GitHub Pages

`Settings` → `Pages` → Source : `Deploy from a branch`, branche `main`, dossier `/ (root)`.
Le site sera servi sur `https://<pseudo>.github.io/XozHub/`.

---

## Héberger sans GitHub

Le site ne dépend pas de GitHub : au chargement, `index.html` remplace le domaine des
commandes par **le domaine sur lequel la page est ouverte** (`location.origin`).
Tu peux donc poser le dossier n'importe où.

Méthode la plus rapide, **sans créer de compte** :

1. va sur <https://app.netlify.com/drop>
2. glisse le dossier complet (les 9 fichiers) dans la page
3. tu obtiens immédiatement un lien public du type `https://xxxx.netlify.app`
4. ouvre ce lien : les commandes affichées pointent déjà vers le bon domaine

> Un deploy fait sans compte Netlify **expire après quelques heures**. Pour le garder,
> crée un compte Netlify gratuit (e-mail suffit, aucun lien avec GitHub) puis clique sur
> **Claim site**. Ensuite, un simple glisser-déposer met le site à jour.

Côté scripts, l'URL de base se transmet de trois façons (dans cet ordre) :

| Méthode | Exemple |
|---|---|
| argument de `install.bat` | `"%TEMP%\xozhub-install.bat" https://mon-site.netlify.app` |
| paramètre PowerShell | `install.ps1 -Base https://mon-site.netlify.app` |
| variable d'environnement | `$env:XOZHUB_BASE` (utilisée par `irm ... \| iex`) |

Sans aucun de ces trois, les scripts retombent sur le dépôt GitHub par défaut.

---

## Fichiers

| Fichier | Rôle |
|---|---|
| `xozhub.ps1` | moteur : UI, config, streaming API |
| `xozhub.bat` | lanceur cmd (UTF-8, choix PowerShell 7 / 5.1) |
| `install-local.bat` | installeur **hors ligne** (copie locale, aucun besoin de GitHub) |
| `install.bat` / `install.ps1` | installeur en ligne (téléchargement) |
| `uninstall.bat` / `uninstall.ps1` | désinstalleur |
| `index.html` | site d'installation (thème cyberpunk) |

---

## Prérequis

- Windows 10 ou 11
- PowerShell 5.1 (fourni avec Windows) — PowerShell 7 détecté automatiquement si présent
- Une connexion internet et une clé API

Non affilié à Anthropic. « Claude » est une marque d'Anthropic.
