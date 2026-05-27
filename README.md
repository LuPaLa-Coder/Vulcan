# Vulcan C# Agent

**Modern C# Development with Cloud-Native Architecture (AWS/Azure/Generic)**

Vulcan è un agente esperto di sviluppo C# e .NET 8+ specializzato nella creazione di **codice production-ready** con architetture cloud-native. Supporta AWS, Azure e ambienti provider-agnostic con pattern architetturali puliti, dependency injection, logging strutturato e best practices di sicurezza.

Disponibile in due modalità: **Skill** (agent framework) e **Agent** (VS Code Copilot).

---

## Caratteristiche Principali

- **Architettura Pulita** — N-Tier, Clean Architecture, Repository Pattern, SOLID principles
- **Cloud-Native** — Lambda (AWS), Functions (Azure), serverless e containerizzato (ECS/Container Apps)
- **Logging & Observability** — Serilog strutturato, correlazione distribuita, telemetria
- **Sicurezza** — Credential handling, encryption, vault integration, least privilege
- **Data Patterns** — Repository Pattern, Entity Framework, DynamoDB, Cosmos DB, LiteDB, MongoDB
- **Resilienza** — Retry policies, circuit breakers, timeout handling, graceful degradation

---

## Installazione

### Modalità Skill (agent framework)

Installazione globale tramite CLI:

```bash
npx skills add PaoEng/Vulcan --skill Vulcan -g -y
```

Oppure per il solo progetto corrente (senza `-g`):

```bash
npx skills add PaoEng/Vulcan --skill Vulcan -y
```

Una volta installata, la skill viene caricata on-demand dall'agente host quando necessario.

### Modalità Agent (VS Code Copilot)

Copia `Vulcan.agent.md` nella directory degli agenti del tuo profilo:

```bash
# Linux/macOS
cp Vulcan.agent.md ~/.copilot/agents/

# Windows
copy Vulcan.agent.md %USERPROFILE%\.copilot\agents\
```

Oppure posiziona il file `Vulcan.agent.md` direttamente nella root del workspace per un agent locale al progetto.

Dopo l'installazione, Vulcan appare nel dropdown degli agenti di GitHub Copilot Chat.

Per la guida completa con prerequisites e configurazione cloud, vedi **[Installation Guide](./vulcan/docs/installation.md)**.

---

## Skill vs Agent — Differenze

| Caratteristica | Skill | Agent (VS Code) |
|---|---|---|
| **Attivazione** | On-demand dall'agente host | Selezione diretta dal dropdown Copilot |
| **Installazione** | `npx skills add ...` | Copia `Vulcan.agent.md` |
| **Tool access** | Eredita i tool dell'agente host | Tutti i tool (`*`): file, terminal, build |
| **Handoff ad Anubis** | Non incluso | Bottone integrato "Code Review con Anubis" |
| **Argument hint** | Non presente | Suggerimento guidato nell'input chat |
| **Composizione** | Componibile con altre skill nello stesso workflow | Sessione dedicata e autonoma |
| **Contesto** | Iniettato nella conversazione corrente | Contesto persistente per tutta la sessione |
| **Ideale per** | Integrare Vulcan in pipeline agent esistenti | Sessioni dedicate di sviluppo C# / vibe coding |

### Quando usare la Skill

- Vuoi usare Vulcan come componente in un workflow multi-agente
- Il tuo agente host gestisce già l'orchestrazione (tool, file, build)
- Hai bisogno di combinare Vulcan con altre skill nello stesso contesto

### Quando usare l'Agent

- Vuoi una sessione dedicata e autonoma di sviluppo C#
- Hai bisogno del bottone di handoff diretto ad **Anubis** per code review
- Preferisci selezionare Vulcan direttamente dal dropdown VS Code Copilot
- Stai lavorando in modalità vibe coding con accesso completo a file e terminale

---

## Struttura Repository

```
Vulcan/
├── Vulcan.agent.md          # VS Code Copilot Agent
├── README.md
└── vulcan/
    ├── SKILL.md             # Agent Framework Skill
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

## Quick Start

### Come Skill

La skill viene attivata automaticamente dall'agente host. Nessun comando esplicito richiesto dopo l'installazione.

### Come Agent (VS Code)

1. Apri GitHub Copilot Chat in VS Code
2. Seleziona **Vulcan** dal dropdown degli agenti
3. Descrivi cosa vuoi costruire:

```
"Crea un endpoint REST per gestire ordini con validazione,
 logging strutturato e persistenza su Cosmos DB (Azure)"
```

4. Vulcan rileva il target (Azure da Cosmos DB) e genera il codice completo:
   - `OrderController.cs`
   - `OrderService.cs`
   - `OrderRepository.cs`
   - Dependency injection setup
   - Unit test (MSTest 3.x)
   - Bicep per IaC

5. Al termine, usa il bottone **"Code Review con Anubis"** per la review automatica.

Per esempi dettagliati, vedi **[Usage Guide](./vulcan/docs/usage.md)** e **[Examples](./vulcan/docs/examples.md)**.

---

## Output

Ogni risposta Vulcan include:

- **Codice C# completo** — classi, interfacce, repository, registrazioni DI
- **appsettings.json** — configurazione development e production
- **XML documentation** — con esempi d'uso su ogni metodo pubblico
- **Unit test** — MSTest 3.x con pattern moderni
- **Dockerfile** — multi-stage build + docker-compose.yml
- **README.md + ARCHITECTURE.md + API.md** (se applicabile)

Per `[AWS]`: aggiunge CDK Stack, SAM template, `AWS-SETUP.md`, IAM policies, LocalStack compose  
Per `[Azure]`: aggiunge Bicep/Terraform, `AZURE-SETUP.md`, Managed Identity config

---

## Integrazione con Anubis

**Standalone**: Vulcan genera codice completo e indipendente.

**Collaborativo**: Usa Vulcan per l'implementazione e **Anubis** per la code review strutturata di sicurezza e qualità.

- In modalità **Agent**: bottone "Code Review con Anubis" disponibile al termine di ogni sessione
- In modalità **Skill**: avvia manualmente Anubis passando il codice generato da Vulcan

---

## Risorse

- **[Installation Guide](./vulcan/docs/installation.md)** — Setup e prerequisites
- **[Usage Guide](./vulcan/docs/usage.md)** — Workflow e comandi
- **[Examples](./vulcan/docs/examples.md)** — Scenari real-world
- **[AWS Templates](./vulcan/docs/vulcan-aws-templates.md)** — Boilerplate Lambda, CDK, Well-Architected
- **[Azure Templates](./vulcan/docs/vulcan-azure-templates.md)** — Boilerplate Functions, Bicep, Best Practices
- **[Vulcan Agent](./Vulcan.agent.md)** — Manifest completo agent VS Code
- **[Vulcan Skill](./vulcan/SKILL.md)** — Manifest completo skill framework

---

**For information on other agents, see the main [Agents README](../README.md).**
