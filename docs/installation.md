# Vulcan Installation Guide

## One-Liner Global Install (Recommended)

Installa Vulcan automaticamente su tutti i coding agent rilevati:

```bash
curl -fsSL https://raw.githubusercontent.com/PaoEng/Vulcan/main/install.sh | bash
```

Lo script:
1. Rileva automaticamente quali coding agent hai installato
2. Copia `Vulcan.agent.md` nella directory agent corretta per ciascuno
3. Crea un backup se Vulcan era già installato

## Installazione Selettiva

```bash
# Prima clona il repo
git clone https://github.com/PaoEng/Vulcan.git
cd Vulcan

# Solo per Claude Code
./install.sh --agent claude

# Solo per OpenCode
./install.sh --agent opencode

# Solo per GitHub Copilot (VS Code / CLI)
./install.sh --agent copilot

# Solo per Cursor
./install.sh --agent cursor

# Solo per Windsurf
./install.sh --agent windsurf

# Solo per OpenAI Codex
./install.sh --agent codex

# Project-local (solo directory corrente)
./install.sh --local
```

## Disinstallazione

```bash
./install.sh --uninstall
```

## Installazione Manuale

Copia `Vulcan.agent.md` nella directory agent del tuo coding tool:

| Tool | Directory Agent |
|------|----------------|
| **Claude Code** | `~/.claude/agents/` |
| **OpenCode** | `~/.opencode/agents/` |
| **GitHub Copilot** | `~/.copilot/agents/` |
| **Cursor** | `~/.cursor/agents/` |
| **Windsurf** | `~/.windsurf/agents/` |
| **Codex (OpenAI)** | `~/.codex/agents/` |
| **Project-local** | `.claude/agents/` nella root del progetto |

```bash
# Linux/macOS
cp Vulcan.agent.md ~/.claude/agents/

# Windows
copy Vulcan.agent.md %USERPROFILE%\.claude\agents\
```

Dopo l'installazione, Vulcan appare nel dropdown/menu degli agenti del tuo coding tool.

## Prerequisites

### Required
- **Un coding agent compatibile**: Claude Code, OpenCode, GitHub Copilot, Cursor, Windsurf, o Codex
- **.NET SDK 10.0+** (o 8.0+ per progetti esistenti)
  ```bash
  dotnet --version
  ```
- **Git** (per clonare il repo, opzionale con install via curl)

### Recommended
- **Docker** (per testing containerizzato)
- **AWS CLI** (se usi target AWS)
- **Azure CLI** (se usi target Azure)

## Cloud Setup (Optional)

### AWS Setup (per target Lambda/ECS)

```bash
aws configure
npm install -g aws-cdk
```

### Azure Setup (per target Functions/Container Apps)

```bash
az login
az bicep install
```

## Verification

Verifica che Vulcan sia installato:

```bash
# Controlla che il file agent sia presente
ls -la ~/.claude/agents/Vulcan.agent.md      # Claude Code
ls -la ~/.opencode/agents/Vulcan.agent.md    # OpenCode
ls -la ~/.copilot/agents/Vulcan.agent.md     # GitHub Copilot
ls -la ~/.cursor/agents/Vulcan.agent.md      # Cursor
```

Poi apri il tuo coding tool e seleziona **Vulcan** dal menu agent.

## Quick Test

1. Apri il tuo coding tool e seleziona **Vulcan** dal menu agent
2. Richiedi un semplice endpoint:
   ```
   Crea un API endpoint C# per ottenere dati utente da Cosmos DB
   ```
3. Vulcan genera il codice completo con Controller, Service, Repository, DI, test, e IaC

## Troubleshooting

### Agent non appare nel menu

- Verifica che il file sia nella directory corretta
- Riavvia il coding tool
- Controlla che il nome file sia esattamente `Vulcan.agent.md`

### "Target cloud ambiguous"

- Vulcan chiederà una sola domanda: _"AWS, Azure o provider-agnostic?"_
- Rispondi con uno dei tre target

### Il codice generato non compila

- Assicurati di avere .NET 10.0+ installato: `dotnet --version`
- Esegui `dotnet restore` nella directory del progetto generato
- Controlla il target framework nei file `.csproj`

### Connessione ai servizi cloud fallita

- Verifica le credenziali (`aws configure`, `az login`)
- Controlla i permessi del servizio (IAM per AWS, RBAC per Azure)
- Assicurati che il servizio esista nel tuo account/subscription

---

## Next Steps

- Leggi la **[Usage Guide](./usage.md)** per i workflow dettagliati
- Vedi gli **[Examples](./examples.md)** per scenari real-world
- Esplora i template cloud: **[AWS](./vulcan-aws-templates.md)** · **[Azure](./vulcan-azure-templates.md)**

---

**Repository**: https://github.com/PaoEng/Vulcan.git
