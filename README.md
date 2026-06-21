# Vulcan C# Agent

**Modern C# Development with Cloud-Native Architecture (AWS/Azure/Generic)**

Vulcan è un agente esperto di sviluppo C# e .NET 10 LTS / .NET 8 LTS specializzato nella creazione di **codice production-ready** con architetture cloud-native. Supporta AWS, Azure e ambienti provider-agnostic con pattern architetturali puliti, dependency injection, logging strutturato e best practices di sicurezza.

**Unico formato: Agent** — installabile globalmente su tutti i coding agent (Claude Code, OpenCode, GitHub Copilot, Cursor, Windsurf, Codex).

---

## Caratteristiche Principali

- **Architettura Pulita** — N-Tier, Clean Architecture, Repository Pattern, SOLID principles
- **Cloud-Native** — Lambda (AWS), Functions (Azure), serverless e containerizzato (ECS/Container Apps)
- **Logging & Observability** — Serilog strutturato, OpenTelemetry, correlazione distribuita, telemetria
- **Sicurezza** — Credential handling, encryption, vault integration, least privilege, SBOM
- **Data Patterns** — Repository Pattern, Entity Framework, DynamoDB, Cosmos DB, LiteDB, MongoDB
- **Resilienza** — Retry policies, circuit breakers, timeout handling, graceful degradation

---

## Installazione

### One-Liner Globale (tutti gli agent)

```bash
curl -fsSL https://raw.githubusercontent.com/LuPala_Coder/Vulcan/main/install.sh | bash
```

Lo script rileva automaticamente quali coding agent hai installato e copia Vulcan nella directory corretta per ciascuno.

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

Copia `Vulcan.agent.md` nella directory agent del tuo tool:

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
cp Vulcan.agent.md ~/.claude/agents/

# Esempio per GitHub Copilot (VS Code)
cp Vulcan.agent.md ~/.copilot/agents/
```

Dopo l'installazione, Vulcan appare nel dropdown/menu degli agenti del tuo coding tool.

Per la guida completa con prerequisites e configurazione cloud, vedi **[Installation Guide](./docs/installation.md)**.

---

## Come Usare Vulcan

1. Seleziona **Vulcan** dal menu agent del tuo coding tool
2. Descrivi cosa vuoi costruire:

```
"Crea un endpoint REST per gestire ordini con validazione,
 logging strutturato e persistenza su Cosmos DB (Azure)"
```

3. Vulcan rileva il target (Azure da Cosmos DB) e genera il codice completo:
   - `OrderController.cs`
   - `OrderService.cs`
   - `OrderRepository.cs`
   - Dependency injection setup
   - Unit test (MSTest 3.6+/4.x)
   - Bicep per IaC
   - Dockerfile + docker-compose

Per esempi dettagliati, vedi **[Usage Guide](./docs/usage.md)** e **[Examples](./docs/examples.md)**.

---

## Struttura Repository

```
Vulcan/
├── Vulcan.agent.md              # Manifesto operativo dell'agente
├── install.sh                   # Script di installazione globale
├── README.md
└── docs/
    ├── installation.md
    ├── usage.md
    ├── examples.md
    ├── vulcan-aws-templates.md   # Boilerplate, CDK, Well-Architected AWS
    └── vulcan-azure-templates.md # Boilerplate, Bicep, Best Practices Azure
```

---

## Casi d'Uso

- **Nuove feature C#** — Da specifica a codice completo production-ready
- **Refactoring architetturale** — Modernizzazione di codice legacy
- **Cloud migration** — Porta codice da on-premise a AWS/Azure
- **Serverless workflows** — Lambda functions, Azure Functions con pattern puliti
- **API REST/gRPC** — Backend completo con autenticazione e validazione
- **Worker/Background jobs** — Processing asincrono, message queues, event-driven
- **Library & NuGet packages** — Codice riutilizzabile con documentazione
- **Infrastructure-as-Code** — CDK (AWS) e Bicep/Terraform (Azure) patterns

---

## Target Cloud

Vulcan rileva automaticamente il target cloud dal contesto:

| Indicatori | Target |
|-----------|--------|
| Lambda, DynamoDB, S3, SQS, SNS, ECS, Fargate, API Gateway | **AWS** |
| Functions, Key Vault, Cosmos DB, Service Bus, Container Apps, Bicep | **Azure** |
| Nessuno specifico, provider-agnostic | **Generic** |

Se non è chiaro, Vulcan pone **una sola domanda**: _"AWS, Azure o provider-agnostic?"_

---

## Output

Ogni risposta Vulcan include:

- **Codice C# completo** — classi, interfacce, repository, registrazioni DI
- **appsettings.json** — configurazione development e production
- **XML documentation** — con esempi d'uso su ogni metodo pubblico
- **Unit test** — MSTest 3.6+/4.x con pattern moderni
- **Dockerfile** — multi-stage build + docker-compose.yml
- **README.md + ARCHITECTURE.md + API.md** (se applicabile)

Per `[AWS]`: aggiunge CDK Stack, SAM template, `AWS-SETUP.md`, IAM policies, LocalStack compose  
Per `[Azure]`: aggiunge Bicep/Terraform, `AZURE-SETUP.md`, Managed Identity config

---

## Integrazione con Anubis

**Standalone**: Vulcan genera codice completo e indipendente.

**Collaborativo**: Usa Vulcan per l'implementazione e **Anubis** per la code review strutturata di sicurezza e qualità.

- Al termine di ogni sessione Vulcan produce un handoff consigliato verso Anubis
- Passa il codice generato da Vulcan ad Anubis per una review completa

---

## Risorse

- **[Installation Guide](./docs/installation.md)** — Setup e prerequisites
- **[Usage Guide](./docs/usage.md)** — Workflow e comandi
- **[Examples](./docs/examples.md)** — Scenari real-world
- **[AWS Templates](./docs/vulcan-aws-templates.md)** — Boilerplate Lambda, CDK, Well-Architected
- **[Azure Templates](./docs/vulcan-azure-templates.md)** — Boilerplate Functions, Bicep, Best Practices
- **[Vulcan Agent](./Vulcan.agent.md)** — Manifesto completo dell'agente (47KB)

---

**For information on other agents, see the main [Agents README](../README.md).**
