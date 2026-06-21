# Vulcan Installation Guide

## One-Liner Global Install (Recommended)

Installa tutti e tre gli agenti Vulcan (Core, AWS, Azure) automaticamente su ogni coding agent rilevato:

```bash
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/Vulcan/main/install.sh | bash
```

Lo script:
1. Rileva automaticamente quali coding agent hai installato
2. Copia `Vulcan.Core.agent.md`, `Vulcan.AWS.agent.md`, `Vulcan.Azure.agent.md` nella directory agent corretta
3. Copia i template AWS e Azure nella subdirectory `vulcan-templates/`
4. Rimuove automaticamente l'agente legacy `Vulcan.agent.md` (v1/v2) se presente
5. Crea un backup se usi l'opzione `--backup`

## Installazione Selettiva

```bash
# Prima clona il repo
git clone https://github.com/LuPaLa-Coder/Vulcan.git
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

Copia i tre file agent nella directory del tuo coding tool:

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
# Linux/macOS — Claude Code
cp Vulcan.Core.agent.md ~/.claude/agents/
cp Vulcan.AWS.agent.md ~/.claude/agents/
cp Vulcan.Azure.agent.md ~/.claude/agents/

# Linux/macOS — GitHub Copilot
cp Vulcan.Core.agent.md ~/.copilot/agents/
cp Vulcan.AWS.agent.md ~/.copilot/agents/
cp Vulcan.Azure.agent.md ~/.copilot/agents/

# Windows — Claude Code
copy Vulcan.Core.agent.md %USERPROFILE%\.claude\agents\
copy Vulcan.AWS.agent.md %USERPROFILE%\.claude\agents\
copy Vulcan.Azure.agent.md %USERPROFILE%\.claude\agents\
```

Dopo l'installazione, **Vulcan-Core**, **Vulcan-AWS** e **Vulcan-Azure** appaiono nel dropdown/menu degli agenti del tuo coding tool.

### Copia Template (opzionale ma consigliato)

```bash
mkdir -p ~/.claude/agents/vulcan-templates
cp docs/vulcan-aws-templates.md ~/.claude/agents/vulcan-templates/
cp docs/vulcan-azure-templates.md ~/.claude/agents/vulcan-templates/
```

## Prerequisites

### Required
- **Un coding agent compatibile**: Claude Code, OpenCode, GitHub Copilot, Cursor, Windsurf, o Codex
- **.NET SDK 8.0+** (o 9.0+ per feature specifiche)
  ```bash
  dotnet --version
  ```
- **Git** (per clonare il repo, opzionale con install via curl)

### Recommended
- **Docker** (per testing containerizzato)
- **AWS CLI** (se usi Vulcan-AWS)
- **Azure CLI** (se usi Vulcan-Azure)

## Cloud Setup (Optional)

### AWS Setup (per Vulcan-AWS)

```bash
aws configure
npm install -g aws-cdk
```

### Azure Setup (per Vulcan-Azure)

```bash
az login
az bicep install
```

## Verifica

Verifica che gli agenti Vulcan siano installati:

```bash
# Claude Code
ls -la ~/.claude/agents/Vulcan.Core.agent.md
ls -la ~/.claude/agents/Vulcan.AWS.agent.md
ls -la ~/.claude/agents/Vulcan.Azure.agent.md

# GitHub Copilot
ls -la ~/.copilot/agents/Vulcan.Core.agent.md
ls -la ~/.copilot/agents/Vulcan.AWS.agent.md
ls -la ~/.copilot/agents/Vulcan.Azure.agent.md
```

Poi apri il tuo coding tool e seleziona l'agente Vulcan appropriato dal menu.

## Quick Test

1. Apri il tuo coding tool e seleziona **Vulcan-Core** dal menu agent
2. Richiedi un semplice endpoint:
   ```
   Crea un API endpoint C# per ottenere dati utente
   ```
3. Vulcan-Core genera il codice completo

4. Prova anche **Vulcan-AWS**:
   ```
   Crea una Lambda function con DynamoDB
   ```
5. E **Vulcan-Azure**:
   ```
   Crea una Azure Function con Cosmos DB
   ```

## Troubleshooting

### Agenti non appaiono nel menu

- Verifica che i file siano nella directory corretta
- Riavvia il coding tool
- Controlla che i nomi file siano esattamente `Vulcan.Core.agent.md`, `Vulcan.AWS.agent.md`, `Vulcan.Azure.agent.md`

### "Quale agente Vulcan devo usare?"

- **Vulcan-Core**: API generiche, console app, librerie, gRPC — nessun cloud specifico
- **Vulcan-AWS**: Lambda, DynamoDB, S3, SQS, SNS, ECS, CDK
- **Vulcan-Azure**: Functions, Cosmos DB, Service Bus, Container Apps, Bicep

### Il codice generato non compila

- Assicurati di avere .NET 8.0+ installato: `dotnet --version`
- Esegui `dotnet restore` nella directory del progetto generato
- Controlla il target framework nei file `.csproj`

### Connessione ai servizi cloud fallita

- Verifica le credenziali (`aws configure`, `az login`)
- Controlla i permessi del servizio (IAM per AWS, RBAC per Azure)
- Assicurati che il servizio esista nel tuo account/subscription

### Migrazione da Vulcan v2 (legacy)

Se avevi installato `Vulcan.agent.md` (v1/v2), l'installer v3.0 lo rimuove automaticamente. I tre nuovi agenti sostituiscono completamente il vecchio agente unificato. Se vuoi mantenere il vecchio agente, rinominalo prima di eseguire l'installer.

---

## Next Steps

- Leggi la **[Usage Guide](./usage.md)** per i workflow dettagliati
- Vedi gli **[Examples](./examples.md)** per scenari real-world
- Esplora i template cloud: **[AWS](./vulcan-aws-templates.md)** · **[Azure](./vulcan-azure-templates.md)**

---

**Repository**: https://github.com/LuPaLa-Coder/Vulcan.git
