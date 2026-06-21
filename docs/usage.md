# Vulcan Usage Guide

## Overview

La famiglia Vulcan è composta da tre agenti specializzati per lo sviluppo C#:

| Agente | Target | Quando usarlo |
|---|---|---|
| **Vulcan-Core** | Provider-agnostic | Console app, API REST, Minimal API, gRPC, librerie, worker service |
| **Vulcan-AWS** | AWS | Lambda, DynamoDB, SQS, SNS, S3, ECS, API Gateway, CDK |
| **Vulcan-Azure** | Azure | Functions, Cosmos DB, Service Bus, Container Apps, Key Vault, Bicep |

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
- DynamoDB data access
- SQS/SNS messaging
- Step Functions workflow
- ECS Fargate container
- CDK infrastructure (C#)
- CloudWatch observability

### Quando usare Vulcan-Azure

- Azure Functions (HTTP trigger, Service Bus trigger, Timer trigger)
- Cosmos DB data access
- Service Bus messaging
- Durable Functions workflow
- Container Apps
- Bicep infrastructure
- Application Insights observability

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
