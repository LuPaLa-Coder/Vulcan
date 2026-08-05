# Vulcan C# Agent Family

**Modern C# Development — Four Specialized Agents for Every Target**

Vulcan è una famiglia di quattro agenti specializzati per lo sviluppo C# e .NET 10 LTS, ciascuno ottimizzato per un target specifico:

| Agente | Target | File |
|---|---|---|
| **Vulcan-Core** | Provider-agnostic: API REST, Minimal API, gRPC, console, librerie, worker + API versioning, OpenAPI | `Vulcan.Core.agent.md` |
| **Vulcan-AWS** | AWS cloud-native: Lambda, DynamoDB, SQS, SNS, S3, ECS, CDK + EventBridge Pipes, CloudFront, API GW v2, LocalStack, cdk-nag | `Vulcan.AWS.agent.md` |
| **Vulcan-Azure** | Azure cloud-native: Functions, Cosmos DB, Service Bus, Container Apps, Bicep + Durable Functions catalog, Logic Apps, blue-green, Azurite, PSRule | `Vulcan.Azure.agent.md` |
| **Vulcan-SCA** | Software Composition Analysis per NuGet: vulnerabilità, deprecazioni e outdated package con remediation loop | `Vulcan.SCA.agent.md` |

**Unico formato: Agent** — installabile globalmente su tutti i coding agent (Claude Code, OpenCode, GitHub Copilot, Cursor, Windsurf, Codex).

---

## Perché Quattro Agenti?

Dopo l'analisi del manifesto Vulcan v2 (47KB), abbiamo identificato che un prompt monolitico causa:
- **Context window saturation**: le istruzioni in fondo vengono dimenticate
- **Applicazione inconsistente**: regole generiche e cloud-specifiche competono
- **Token sprecati**: il modello processa regole AWS anche quando lavori su Azure

La soluzione: **quattro agenti specializzati, invocati on-demand**. Ogni agente è un motore decisionale auto-sufficiente per il suo target: Core 20KB, AWS/Azure 12KB ciascuno, SCA dedicato alla sicurezza delle dipendenze (vs 47KB del manifesto monolitico v2).

---

## Caratteristiche Principali

- **Architettura Adattiva** — Flat, Vertical Slice, Clean Architecture, N-Tier in base alla complessità
- **Cloud-Native** — Pattern specifici per AWS (CDK, Lambda Powertools, API Gateway v2, EventBridge Pipes, CloudFront) e Azure (Bicep, Managed Identity, Durable Functions catalog, Container Apps blue-green)
- **Minimal APIs** — Default per API REST semplici, con MapGroup, IEndpointFilter, OpenAPI
- **Result Pattern con OneOf** — Error handling type-safe senza eccezioni
- **.NET Aspire** — Orchestrazione locale per progetti multi-servizio
- **gRPC & IAsyncEnumerable** — Streaming e comunicazione service-to-service
- **Native AOT** — Cold start ottimizzato per Lambda e CLI
- **Observability** — Serilog strutturato, OpenTelemetry, health checks
- **Sicurezza** — IAM Roles / Managed Identity, Key Vault, least privilege, SBOM
- **Supply Chain** — Central Package Management, lock file, package source mapping
- **Testing Cloud-Native** — LocalStack (AWS), Azurite + Cosmos DB Emulator (Azure), TestContainers, cdk-nag, PSRule
- **API Versioning** — URL path, query string, header e content negotiation strategies

---

## Installazione

### One-Liner Globale (tutti gli agent)

```bash
curl -fsSL https://raw.githubusercontent.com/LuPaLa-Coder/Vulcan/main/install.sh | bash
```

Lo script installa **tutti e quattro gli agenti** (Vulcan-Core, Vulcan-AWS, Vulcan-Azure, Vulcan-SCA) in ogni coding agent rilevato.

### Opzioni di Installazione

```bash
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

# Solo per Codex (OpenAI)
./install.sh --agent codex

# Solo nella directory corrente (project-local)
./install.sh --local

# Disinstallazione
./install.sh --uninstall
```

### Installazione Manuale

Copia i file agent nella directory del tuo tool:

| Tool | Directory Agent |
|------|----------------|
| **Claude Code** | `~/.claude/agents/` |
| **OpenCode** | `~/.opencode/agents/` |
| **GitHub Copilot** | `~/.copilot/agents/` |
| **Cursor** | `~/.cursor/agents/` |
| **Windsurf** | `~/.windsurf/agents/` |
| **Codex (OpenAI)** | `~/.codex/agents/` |

```bash
# Esempio per Claude Code
cp Vulcan.Core.agent.md ~/.claude/agents/
cp Vulcan.AWS.agent.md ~/.claude/agents/
cp Vulcan.Azure.agent.md ~/.claude/agents/
cp Vulcan.SCA.agent.md ~/.claude/agents/
```

Dopo l'installazione, **Vulcan-Core**, **Vulcan-AWS**, **Vulcan-Azure** e **Vulcan-SCA** appaiono nel menu agenti del tuo coding tool.

Per la guida completa, vedi **[Installation Guide](./docs/installation.md)** .

---

## Come Usare Vulcan

1. Seleziona l'agente giusto dal menu del tuo coding tool:
   - **Vulcan-Core** per API generiche, console app, librerie
   - **Vulcan-AWS** per Lambda, DynamoDB, SQS, CDK
   - **Vulcan-Azure** per Functions, Cosmos DB, Service Bus, Bicep
   - **Vulcan-SCA** per analizzare e correggere vulnerabilità/deprecazioni/outdated di package NuGet

2. Descrivi cosa vuoi costruire:

```
"Crea un endpoint REST per gestire ordini con validazione,
 logging strutturato e persistenza su Cosmos DB"
```

3. Vulcan-Azure rileva il target e genera il codice completo con:
   - `OrderController.cs` (o Minimal API)
   - `OrderService.cs`
   - `CosmosOrderRepository.cs`
   - Dependency injection setup
   - Unit test (MSTest 3.6+/4.x) con smoke test
   - Bicep per IaC
   - Dockerfile + docker-compose (con Azurite)

Per esempi dettagliati, vedi **[Usage Guide](./docs/usage.md)** e **[Examples](./docs/examples.md)** .

---

## Struttura Repository

```
Vulcan/
├── Vulcan.Core.agent.md          # Agente Generic/.NET (provider-agnostic)
├── Vulcan.AWS.agent.md           # Agente AWS cloud-native
├── Vulcan.Azure.agent.md         # Agente Azure cloud-native
├── Vulcan.SCA.agent.md           # Agente SCA per NuGet dependency analysis/remediation
├── install.sh                    # Script di installazione globale (v3.1)
├── README.md
└── docs/
    ├── installation.md
    ├── usage.md
    ├── examples.md
    ├── vulcan-aws-templates.md    # Boilerplate, CDK, Well-Architected AWS
    └── vulcan-azure-templates.md  # Boilerplate, Bicep, Best Practices Azure
```

---

## Casi d'Uso

- **Nuove feature C#** — Da specifica a codice completo production-ready
- **Refactoring architetturale** — Modernizzazione di codice legacy
- **Cloud migration** — Porta codice da on-premise a AWS/Azure
- **Serverless workflows** — Lambda functions, Azure Functions con pattern puliti
- **API REST/gRPC** — Backend completo con autenticazione e validazione
- **Minimal API** — API leggere con ASP.NET Core Minimal APIs
- **Worker/Background jobs** — Processing asincrono, message queues, event-driven
- **Library & NuGet packages** — Codice riutilizzabile con documentazione
- **Infrastructure-as-Code** — CDK (AWS) e Bicep (Azure) patterns

---

## Quale Agente Usare?

| Scenario | Agente |
|---|---|
| Console app, libreria, API generica, gRPC service | **Vulcan-Core** |
| Lambda, DynamoDB, S3, SQS, SNS, ECS, CDK, API Gateway, CloudFront, EventBridge Pipes | **Vulcan-AWS** |
| Functions, Cosmos DB, Service Bus, Container Apps, Bicep, Durable Functions, Logic Apps | **Vulcan-Azure** |
| Dipendenze NuGet da scansionare/remediate: vulnerabilità, deprecazioni, outdated package | **Vulcan-SCA** |
| Progetto multi-cloud o ibrido | Inizia con **Vulcan-Core**, poi consulta AWS/Azure per le sezioni cloud |

---

## Output

Ogni agente Vulcan genera:

- **Codice C# completo** — classi, interfacce, repository, registrazioni DI
- **appsettings.json** — configurazione development e production
- **XML documentation** — con esempi d'uso su ogni metodo pubblico
- **Unit test** — MSTest 3.6+/4.x con pattern moderni + smoke test obbligatori
- **Dockerfile** — multi-stage build + docker-compose.yml
- **README.md + ARCHITECTURE.md + API.md** (se applicabile)

`Vulcan-AWS` aggiunge: CDK Stack, SAM template, `AWS-SETUP.md`, IAM policies, LocalStack compose
`Vulcan-Azure` aggiunge: Bicep, `AZURE-SETUP.md`, Managed Identity config, Azurite compose

---

## Integrazione con Anubis

**Standalone**: Ogni agente Vulcan genera codice completo e indipendente.

**Collaborativo**: Usa Vulcan per l'implementazione e **Anubis** per la code review strutturata.

- Al termine di ogni sessione Vulcan produce un handoff strutturato verso Anubis
- Passa il codice generato da Vulcan ad Anubis per una review completa
- Template di handoff incluso in ogni agente

---

## Risorse

- **[Installation Guide](./docs/installation.md)** — Setup e prerequisites
- **[Usage Guide](./docs/usage.md)** — Workflow e comandi
- **[Examples](./docs/examples.md)** — Scenari real-world
- **[AWS Templates](./docs/vulcan-aws-templates.md)** — Boilerplate Lambda, CDK, Well-Architected
- **[Azure Templates](./docs/vulcan-azure-templates.md)** — Boilerplate Functions, Bicep, Best Practices
- **[Vulcan-Core Agent](./Vulcan.Core.agent.md)** — Motore decisionale Generic/.NET (20KB)
- **[Vulcan-AWS Agent](./Vulcan.AWS.agent.md)** — Motore decisionale AWS (12KB)
- **[Vulcan-Azure Agent](./Vulcan.Azure.agent.md)** — Motore decisionale Azure (12KB)
- **[Vulcan-SCA Agent](./Vulcan.SCA.agent.md)** — Motore decisionale SCA per dipendenze NuGet (16KB)

---

**For information on other agents, see the main [Agents README](../README.md).**
