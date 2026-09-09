# Vulcan Usage Guide

## Overview

La famiglia Vulcan è composta da sei agenti specializzati per lo sviluppo C#:

| Agente | Target | Quando usarlo |
|---|---|---|
| **Vulcan-Dispatch** | Entry point intelligente | **Inizio consigliato**: qualsiasi richiesta .NET — rileva il target e delega |
| **Vulcan-Core** | Provider-agnostic | Console app, API REST, Minimal API, gRPC, librerie, worker service |
| **Vulcan-Patterns** | Pattern avanzati | CQRS, SignalR, GraphQL, Feature Flags, caching distribuito, profiling |
| **Vulcan-AWS** | AWS | Lambda, DynamoDB, SQS, SNS, S3, ECS, API Gateway, CDK |
| **Vulcan-Azure** | Azure | Functions, Cosmos DB, Service Bus, Container Apps, Key Vault, Bicep |
| **Vulcan-SCA** | Software Composition Analysis | Scansione/remediation dipendenze NuGet (vulnerabilità, deprecazioni, outdated) |

Ogni agente è completo e auto-sufficiente per il suo target. Scegli l'agente giusto prima di iniziare.

## Workflow

```
1. Scegli l'agente Vulcan appropriato
         ↓
2. Descrivi feature/componente
         ↓
3. Vulcan genera codice C# production-ready
         ↓
4. Review, adatta, integra nel tuo progetto
         ↓
5. Deploy (se applicabile)
```

## Quick Start

1. Seleziona l'agente dal menu del tuo coding tool:
   - **Vulcan-Core** per codice provider-agnostic
   - **Vulcan-AWS** per sviluppo su AWS
   - **Vulcan-Azure** per sviluppo su Azure

2. Descrivi cosa vuoi costruire:

```
"Crea un API REST per gestire ordini con validazione e persistenza"
```

3. L'agente genera tutto il codice necessario.

## Scegliere l'Agente Giusto

### Quando usare Vulcan-Core

- Console application (Spectre.Console)
- API REST generica o Minimal API
- gRPC service
- Libreria NuGet
- Worker service con BackgroundService
- Progetto .NET Aspire multi-servizio
- Refactoring di codice legacy
- Qualsiasi progetto senza servizi cloud specifici

### Quando usare Vulcan-AWS

- Lambda function (API Gateway trigger, S3 trigger, SQS trigger)
- DynamoDB data access (TTL + Streams, single-table design)
- SQS/SNS messaging, EventBridge Pipes
- Step Functions workflow
- API Gateway (REST API / HTTP API v2)
- ECS Fargate container, EKS
- CloudFront + Lambda@Edge + CloudFront Functions
- CDK infrastructure (C#) con cdk-nag
- Secrets Manager / Parameter Store
- CloudWatch observability, Logs Insights
- Testing cloud-native con LocalStack + TestContainers

### Quando usare Vulcan-Azure

- Azure Functions (HTTP trigger, Service Bus trigger, Timer trigger, Durable Functions)
- Cosmos DB data access (query parametrizzate, soft delete, multi-region)
- Service Bus messaging (sessioni, DLQ, batch)
- Container Apps (revisioni, blue-green, traffic splitting)
- App Service, Logic Apps
- Bicep infrastructure + PSRule validation
- Application Insights + OpenTelemetry
- Azure Cache for Redis (tier decision)
- Managed Identity, Key Vault, RBAC
- Testing cloud-native con Azurite + Cosmos DB Emulator + TestContainers

### Quando usare Vulcan-Patterns

- CQRS quando la complessità del dominio (reporting pesante, audit storico) giustifica la separazione read/write
- SignalR per notifiche real-time a più client connessi (non polling)
- GraphQL quando servono query flessibili lato client con schema in evoluzione
- Feature Flags per rollout progressivi e A/B testing
- Caching distribuito avanzato (multi-livello, invalidazione, cache-aside evoluto)
- Performance profiling con BenchmarkDotNet

Usa Vulcan-Patterns solo quando un segnale concreto (scala, latenza, molteplicità di consumer) giustifica la complessità architetturale aggiuntiva. Per generazione base (API REST, storage, setup progetto) usa Vulcan-Core, che delega qui solo quando serve.

### Progetti Multi-Cloud o Ibridi

Se il progetto usa servizi di entrambi i cloud:
1. Inizia con **Vulcan-Core** per la struttura base
2. Per le parti AWS-specifiche, consulta **Vulcan-AWS**
3. Per le parti Azure-specifiche, consulta **Vulcan-Azure**

In futuro, Vulcan supporterà una modalità `[Multi-Cloud]` nativa.

## Common Workflows

### Workflow 1: API REST con Vulcan-Core

**Goal**: Build a complete API REST

1. **Seleziona Vulcan-Core**

2. **Request**:
   ```
   Crea un'API REST per la gestione utenti con:
   - Minimal API o Controller (in base alla complessità)
   - PostgreSQL + EF Core
   - FluentValidation
   - Serilog + OpenTelemetry
   - MSTest con smoke test
   ```

3. **Vulcan-Core genera**:
   ```
   ✓ Program.cs (Minimal API con MapGroup)
   ✓ UserService.cs
   ✓ EF Core DbContext
   ✓ CreateUserDto, UserDto (record)
   ✓ UserValidator.cs
   ✓ Tests/ (smoke test incluso)
   ✓ Dockerfile multi-stage
   ```

### Workflow 2: Lambda Function con Vulcan-AWS

**Goal**: Serverless data processing su AWS

1. **Seleziona Vulcan-AWS**

2. **Request**:
   ```
   Crea una Lambda function per processare file CSV:
   - Leggi da S3
   - Valida dati
   - Salva su DynamoDB
   - Lambda Powertools per logging/tracing/metrics
   - CDK Stack
   ```

3. **Vulcan-AWS genera**:
   ```
   ✓ ProcessCsvFunction.cs (Lambda handler con Powertools)
   ✓ CsvProcessor.cs
   ✓ DynamoDbRepository.cs
   ✓ Startup.cs (DI + AWS SDK)
   ✓ Tests/
   ✓ cdk/MyServiceStack.cs
   ✓ docker-compose.yml (LocalStack)
   ```

### Workflow 3: Azure Functions con Vulcan-Azure

**Goal**: API serverless su Azure

1. **Seleziona Vulcan-Azure**

2. **Request**:
   ```
   Crea Azure Functions per gestione prodotti:
   - HTTP trigger (GET, POST, PUT, DELETE)
   - Cosmos DB per persistenza
   - Managed Identity per auth
   - Key Vault per segreti
   - Bicep per IaC
   ```

3. **Vulcan-Azure genera**:
   ```
   ✓ HttpTriggerFunction.cs (Isolated Worker)
   ✓ ProductService.cs
   ✓ CosmosProductRepository.cs (soft delete, query parametrizzate)
   ✓ Program.cs (Managed Identity + Key Vault)
   ✓ Tests/
   ✓ infra/main.bicep
   ✓ docker-compose.yml (Azurite + Cosmos Emulator)
   ```

### Workflow 4: Refactor Legacy Code con Vulcan-Core

**Goal**: Modernizzare codice legacy

1. **Seleziona Vulcan-Core**

2. **Condividi il codice e richiedi il refactor**:
   ```
   Refactor questa classe DataService in architettura pulita
   con OneOf per error handling, Dependency Injection e logging:

   [paste existing code]
   ```

3. **Vulcan-Core genera**: Interface, Service (con OneOf), Repository, DTOs (record), Validators, Tests

## Output Structure

```
generated/
├── Controllers/              # HTTP entry points (o Minimal API in Program.cs)
├── Services/                 # Business logic
├── Data/
│   ├── Repositories/         # Data access
│   └── Entities/             # Domain models
├── Models/
│   ├── Dto/                  # API DTOs (record types)
│   ├── Validators/           # FluentValidation
│   └── Exceptions/           # Custom exceptions
├── Infrastructure/
│   ├── DependencyInjection.cs
│   ├── Logging.cs
│   └── Configuration.cs
├── Tests/
│   ├── UnitTests/
│   └── IntegrationTests/
├── [CloudProvider]/          # CDK (AWS) o Bicep (Azure)
└── appsettings.json
```

## Advanced Usage

### Custom Project Structure

```
Voglio una struttura multi-layer con:
- Core (business logic)
- Application (use cases)
- Infrastructure (data, cloud)
- Presentation (API)
```

### Cambiare Target Cloud

Se cambi idea sul provider cloud, usa l'agente appropriato per la nuova richiesta:

```
// Prima richiesta con Vulcan-AWS
"Crea un API per ordini su AWS Lambda"

// Poi con Vulcan-Azure
"Converti lo stesso API per Azure Functions"
```

### Include/Exclude Components

```
"API REST con auth, validation e logging.
 Escludi tests e cloud infrastructure"
```

## Best Practices

✅ **Do**:
- Scegli l'agente Vulcan giusto per il tuo target
- Reviewa il codice generato prima di usarlo in produzione
- Comprendi i pattern (OneOf, Minimal API, IAsyncEnumerable)
- Integra incrementalmente nel tuo progetto
- Usa l'handoff ad Anubis per la code review

❌ **Don't**:
- Usare Vulcan-AWS per progetti Azure (e viceversa)
- Copiare/incollare codice senza capirlo
- Saltare i test (ogni agente genera almeno uno smoke test)
- Assumere che il codice generato sia ottimizzato per ogni caso
- Usare credenziali di produzione nei file di configurazione generati
- Deployare senza security review

---

**Pronto per iniziare?** Vedi gli **[Examples](./examples.md)** per scenari real-world.

---

### Workflow 5: Automatic Routing con Vulcan-Dispatch

**Goal**: Lascia che Dispatch rilevi il target e instradi automaticamente

1. **Seleziona Vulcan-Dispatch** (entry point consigliato)

2. **Request generica** (senza indicare il target):
   ```
   "Crea una funzione serverless per processare file CSV,
    salvare su DB e inviare notifica via email"
   ```

3. **Vulcan-Dispatch**:
   - Rileva segnali: "serverless", "file", "DB", "email"
   - Decide: AWS Lambda oppure Azure Functions?
   - Delega a **Vulcan-AWS** o **Vulcan-Azure**
   - L'agente specifico genera il codice completo

### Workflow 6: Dependency Analysis con Vulcan-SCA

**Goal**: Scansionare e correggere vulnerabilità NuGet

1. **Seleziona Vulcan-SCA**

2. **Request**:
   ```
   "Scansiona il progetto per pacchetti vulnerabili,
    deprecati e outdated. Correggi automaticamente."
   ```

3. **Vulcan-SCA esegue**:
   - Legge il `.csproj` / `packages.config`
   - Scansiona i tre assi: vulnerabilità → deprecazioni → outdated
   - Genera fix (upgrade, replace)
   - Delega a **Vulcan-Core** per implementare le correzioni
   - Re-scansiona fino a 0 vulnerabili · 0 deprecati · 0 outdated
   - Ritorna lista cambiamenti + CHANGELOG aggiornato

### Workflow 7: Real-Time Dashboard con Vulcan-Patterns

**Goal**: Aggiungere un dashboard con aggiornamenti live

1. **Request**:
   ```
   "Aggiungi un dashboard con aggiornamenti live degli ordini"
   ```

2. **Vulcan-Dispatch** rileva il segnale "live" → instrada a **Vulcan-Patterns**

3. **Vulcan-Patterns valuta**: notifiche push a più client connessi → SignalR è il pattern corretto (non polling)

4. **Vulcan-Patterns propone**: Hub tipizzato + `IHubContext` per la pubblicazione da servizio

5. **Handoff a Vulcan-Core** per il setup del progetto base (se non esiste già)

6. **Vulcan-Patterns implementa**: Hub + notifier + anti-pattern guardrail (SIG1-5)

