# Vulcan C# Agent Family

**Modern C# Development — Five Specialized Agents for Every Target**

Vulcan è una famiglia di **cinque agenti specializzati** per lo sviluppo C# e .NET 10 LTS, ciascuno ottimizzato per un dominio specifico:

| Agente | Target | File | Dimensione |
|---|---|---|---|
| **Vulcan-Dispatch** | Entry point: rilevamento automatico target (Generic/AWS/Azure) e tipo task (code-gen, SCA) → delega all'agente corretto | `Vulcan.Dispatch.agent.md` | 9.8 KB |
| **Vulcan-Core** | Provider-agnostic: API REST, Minimal API, gRPC, console, librerie, worker + API versioning, OpenAPI, storage locale/self-managed | `Vulcan.Core.agent.md` | 47.2 KB |
| **Vulcan-Patterns** | Advanced patterns: CQRS, SignalR, GraphQL, Feature Flags, Caching, Profiling (quando la complessità lo giustifica) | `Vulcan.Patterns.agent.md` | 9.7 KB |
| **Vulcan-AWS** | AWS cloud-native: Lambda, DynamoDB, SQS, SNS, S3, ECS, CDK + EventBridge Pipes, CloudFront, API GW v2, LocalStack, cdk-nag | `Vulcan.AWS.agent.md` | 32.3 KB |
| **Vulcan-Azure** | Azure cloud-native: Functions, Cosmos DB, Service Bus, Container Apps, Bicep + Durable Functions, Logic Apps, blue-green, Azurite, PSRule | `Vulcan.Azure.agent.md` | 36.7 KB |
| **Vulcan-SCA** | Software Composition Analysis per NuGet: vulnerabilità, deprecazioni, outdated package con remediation loop iterativo (max 10 iter) | `Vulcan.SCA.agent.md` | 17.8 KB |

**Unico formato: Agent** — installabile globalmente su tutti i coding agent (Claude Code, OpenCode, GitHub Copilot, Cursor, Windsurf, Codex).

---

## Perché Sei Agenti Specializzati?

Dopo l'analisi del manifesto Vulcan v2 (47KB monolite), abbiamo identificato che un prompt unico causa:
- **Context window saturation**: le istruzioni in fondo vengono dimenticate
- **Applicazione inconsistente**: regole generiche e cloud-specifiche competono
- **Token sprecati**: il modello processa regole AWS anche quando lavori su Azure
- **Assenza di routing**: no entry point intelligente
- **Pattern avanzati mescolati con CRUD**: complessità nascosta

La soluzione: **sei agenti specializzati, con Dispatch come router**.
- **Vulcan-Dispatch** (9.8KB): entry point routing → rileva target e task → delega all'agente corretto
- **Vulcan-Core** (47.2KB): motore decisionale Generic/.NET (setup, architettura, storage, anti-pattern, observability, qualità)
- **Vulcan-Patterns** (9.7KB): pattern avanzati (CQRS, SignalR, GraphQL, Feature Flags, Caching, Profiling) — quando la complessità lo giustifica
- **Vulcan-AWS** (32.3KB): AWS cloud-native (Lambda, DynamoDB, CDK, EventBridge, …)
- **Vulcan-Azure** (36.7KB): Azure cloud-native (Functions, Cosmos DB, Bicep, Durable Functions, …)
- **Vulcan-SCA** (17.8KB): scansione dipendenze NuGet e remediation loop

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

Lo script installa **tutti i sei agenti** (Vulcan-Dispatch, Vulcan-Core, Vulcan-Patterns, Vulcan-AWS, Vulcan-Azure, Vulcan-SCA) in ogni coding agent rilevato.

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
cp Vulcan.Dispatch.agent.md ~/.claude/agents/
cp Vulcan.Core.agent.md ~/.claude/agents/
cp Vulcan.AWS.agent.md ~/.claude/agents/
cp Vulcan.Azure.agent.md ~/.claude/agents/
cp Vulcan.SCA.agent.md ~/.claude/agents/
```

Dopo l'installazione, tutti e cinque gli agenti appaiono nel menu agenti: **Vulcan-Dispatch** (entry point), **Vulcan-Core**, **Vulcan-AWS**, **Vulcan-Azure** e **Vulcan-SCA**.

Per la guida completa, vedi **[Installation Guide](./docs/installation.md)** .

---

## Come Usare Vulcan

**Entry point consigliato: seleziona sempre Vulcan-Dispatch.** L'agente rileva automaticamente il target e il tipo di task, poi delega all'agente specializzato.

Alternativamente, seleziona l'agente specifico se conosci il target:
   - **Vulcan-Dispatch** per qualsiasi task .NET (routing intelligente) ← **CONSIGLIATO**
   - **Vulcan-Core** per API generiche, console app, librerie, storage locale
   - **Vulcan-AWS** per Lambda, DynamoDB, SQS, CDK
   - **Vulcan-Azure** per Functions, Cosmos DB, Service Bus, Bicep
   - **Vulcan-SCA** per scansione/remediation dipendenze NuGet

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
├── Vulcan.Dispatch.agent.md      # Entry point routing (v2026.8.5.0)
├── Vulcan.Core.agent.md          # Agente Generic/.NET (provider-agnostic)
├── Vulcan.AWS.agent.md           # Agente AWS cloud-native
├── Vulcan.Azure.agent.md         # Agente Azure cloud-native
├── Vulcan.SCA.agent.md           # Agente SCA per NuGet dependency analysis/remediation
├── install.sh                    # Script di installazione globale (v3.2.0)
├── CHANGELOG.md                  # Storico versioni agenti
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
| **Qualsiasi task .NET** (routing automatico consigliato) | **Vulcan-Dispatch** ← *Inizia da qui* |
| Console app, libreria, API generica, gRPC service, storage locale/self-managed | **Vulcan-Core** |
| CQRS, SignalR, GraphQL, Feature Flags, Caching, Profiling (pattern avanzati) | **Vulcan-Patterns** |
| Lambda, DynamoDB, S3, SQS, SNS, ECS, CDK, API Gateway, CloudFront, EventBridge Pipes | **Vulcan-AWS** |
| Functions, Cosmos DB, Service Bus, Container Apps, Bicep, Durable Functions, Logic Apps | **Vulcan-Azure** |
| Scansione/remediation dipendenze NuGet (vulnerabilità, deprecazioni, outdated) | **Vulcan-SCA** |
| Progetto multi-cloud o ibrido | Usa **Vulcan-Dispatch** per routing intelligente |

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
- **[CHANGELOG](./CHANGELOG.md)** — Versioni e storico agenti
- **[AWS Templates](./docs/vulcan-aws-templates.md)** — Boilerplate Lambda, CDK, Well-Architected
- **[Azure Templates](./docs/vulcan-azure-templates.md)** — Boilerplate Functions, Bicep, Best Practices
- **Agenti:**
  - **[Vulcan-Dispatch](./Vulcan.Dispatch.agent.md)** — Entry point routing (9.8 KB, v2026.8.5.0)
  - **[Vulcan-Core](./Vulcan.Core.agent.md)** — Motore decisionale Generic/.NET (47.2 KB)
  - **[Vulcan-AWS](./Vulcan.AWS.agent.md)** — Motore decisionale AWS (32.3 KB)
  - **[Vulcan-Azure](./Vulcan.Azure.agent.md)** — Motore decisionale Azure (36.7 KB)
  - **[Vulcan-SCA](./Vulcan.SCA.agent.md)** — Software Composition Analysis NuGet (17.8 KB)

---

**For information on other agents, see the main [Agents README](../README.md).**
