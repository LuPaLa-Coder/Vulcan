# Vulcan Installation Guide

Installa i sei agenti Vulcan (Dispatch, Core, Patterns, AWS, Azure, SCA).

## Quale metodo per quale tool

| Tool | Metodo |
|------|--------|
| Claude Code | Plugin |
| Copilot CLI | Plugin |
| OpenCode | `install.sh` |
| Cursor, Windsurf, Codex | `install.sh` |

`install.sh` non gestisce Claude Code né Copilot CLI (rifiuta `--agent claude` e `--agent copilot`): avendo il plugin, una seconda installazione via script duplica gli agenti.

## Plugin — Claude Code e Copilot CLI

Il repository è anche un marketplace (`.claude-plugin/marketplace.json` → `plugin/`).

Claude Code:

```
/plugin marketplace add LuPaLa-Coder/Vulcan
/plugin install vulcan@vulcan-marketplace
```

Copilot CLI:

```bash
copilot plugin marketplace add LuPaLa-Coder/Vulcan
copilot plugin install vulcan@vulcan-marketplace
```

Il plugin installa tutti e sei gli agenti, senza filtro per singolo agente. Aggiornamento: `/plugin update` (Claude Code) o `copilot plugin update vulcan`.

Provare un checkout locale prima di pubblicare (Claude Code):

```bash
claude --plugin-dir ./plugin
```

I file in `plugin/agents/` sono generati dai `Vulcan.*.agent.md` in root da `scripts/build-plugin.sh`: rieseguirlo dopo ogni modifica a un agente.

## Script — OpenCode, Cursor, Windsurf, Codex

```bash
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/Vulcan/main/install.sh | bash
```

Lo script:
1. Rileva i coding agent installati (OpenCode, Cursor, Windsurf, Codex)
2. Genera per ciascuno i sei agenti con il frontmatter nativo e, per Dispatch e SCA, il blocco `Host Capability Contract` ricavato da `contracts/host-capabilities.tsv`
3. Rimuove l'agente legacy `Vulcan.agent.md` (v1/v2) se presente
4. Crea un backup con `--backup`

Installazione selettiva da checkout:

```bash
git clone https://github.com/LuPaLa-Coder/Vulcan.git
cd Vulcan

./install.sh --agent opencode   # opencode | cursor | windsurf | codex
./install.sh --backup
./install.sh --uninstall
```

| Tool | Directory agent | Nome file |
|------|-----------------|-----------|
| OpenCode | `~/.config/opencode/agents/` | `vulcan-core.md`, … (lowercase) |
| Cursor | `~/.cursor/agents/` | `Vulcan.Core.agent.md`, … |
| Windsurf | `~/.windsurf/agents/` | `Vulcan.Core.agent.md`, … |
| Codex | `~/.codex/agents/` | `Vulcan.Core.agent.md`, … |

Cursor e Windsurf sono rilevati solo se esiste già la cartella `agents/`; per OpenCode `--agent opencode` la crea.

Non copiare a mano i file `Vulcan.*.agent.md`: senza il frontmatter e il contratto generati dall'installer l'host non sa se può delegare. I template cloud (`docs/vulcan-aws-templates.md`, `docs/vulcan-azure-templates.md`) restano nel repository; non metterli nelle cartelle `agents/` (OpenCode scansiona ricorsivamente e li registrerebbe come agenti).

## Verifica

```bash
# Claude Code
claude plugin list | grep vulcan

# Copilot CLI
copilot plugin list | grep vulcan

# OpenCode
ls ~/.config/opencode/agents | grep vulcan
```

Poi apri il tool e seleziona **Vulcan-Dispatch** (Claude Code: `vulcan:Vulcan-Dispatch`).

## Migrazione da un'installazione via script

Le versioni precedenti installavano in `~/.claude/agents/` e `~/.copilot/agents/` (`Vulcan.*.agent.md`). Con il plugin quei file vanno rimossi, altrimenti ogni agente compare due volte:

```bash
rm ~/.claude/agents/Vulcan.{Dispatch,Core,Patterns,AWS,Azure,SCA}.agent.md
rm ~/.copilot/agents/Vulcan.{Dispatch,Core,Patterns,AWS,Azure,SCA}.agent.md
```

Se avevi copiato i template in `~/.claude/agents/vulcan-templates/`, rimuovi anche quella cartella.

## Prerequisiti

### Richiesti
- **Un coding agent compatibile**: Claude Code, Copilot CLI, OpenCode, Cursor, Windsurf o Codex
- **.NET SDK 10.0+** (`dotnet --version`)
- **Git** (solo per clonare il repo)

### Consigliati
- **Docker** (testing containerizzato)
- **AWS CLI** (Vulcan-AWS) · **Azure CLI** (Vulcan-Azure)

## Cloud Setup (opzionale)

```bash
# AWS (Vulcan-AWS)
aws configure
npm install -g aws-cdk

# Azure (Vulcan-Azure)
az login
az bicep install
```

## Quick Test

1. Seleziona **Vulcan-Dispatch** (o direttamente **Vulcan-Core**) dal menu agent
2. Richiedi: `Crea un API endpoint C# per ottenere dati utente`
3. Prova **Vulcan-AWS**: `Crea una Lambda function con DynamoDB`
4. Prova **Vulcan-Azure**: `Crea una Azure Function con Cosmos DB`

## Troubleshooting

### Agenti non appaiono nel menu

- Plugin: `claude plugin list` / `copilot plugin list` deve mostrare `vulcan@vulcan-marketplace` abilitato
- Script: verifica che i file siano nella directory agent del tool
- Riavvia il coding tool

### Agenti duplicati

Plugin e vecchia installazione via script coesistono: vedi *Migrazione* sopra.

### "Quale agente Vulcan devo usare?"

- **Vulcan-Dispatch**: entry point, sceglie il target
- **Vulcan-Core**: API generiche, console app, librerie, gRPC — nessun cloud specifico
- **Vulcan-Patterns**: CQRS, SignalR, GraphQL, caching, profiling
- **Vulcan-AWS**: Lambda, DynamoDB, S3, SQS, SNS, ECS, CDK
- **Vulcan-Azure**: Functions, Cosmos DB, Service Bus, Container Apps, Bicep
- **Vulcan-SCA**: vulnerabilità, deprecazioni e outdated package NuGet con remediation loop

### Il codice generato non compila

- Verifica .NET 10.0+: `dotnet --version`
- Esegui `dotnet restore` nella directory del progetto
- Controlla il target framework nei `.csproj`

### Connessione ai servizi cloud fallita

- Verifica le credenziali (`aws configure`, `az login`)
- Controlla i permessi (IAM per AWS, RBAC per Azure)
- Assicurati che il servizio esista nel tuo account/subscription

### Migrazione da Vulcan v2 (legacy)

L'installer rimuove automaticamente `Vulcan.agent.md` (v1/v2). I sei agenti attuali sostituiscono completamente il vecchio agente unificato.

---

## Next Steps

- Leggi la **[Usage Guide](./usage.md)** per i workflow dettagliati
- Vedi gli **[Examples](./examples.md)** per scenari real-world
- Esplora i template cloud: **[AWS](./vulcan-aws-templates.md)** · **[Azure](./vulcan-azure-templates.md)**

---

**Repository**: https://github.com/LuPaLa-Coder/Vulcan.git
