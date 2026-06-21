# Vulcan Usage Guide

## Overview

Vulcan generates **production-ready C# code** across three cloud targets:
- **Generic**: Provider-agnostic, local development, library code
- **AWS**: Lambda, ECS, API Gateway, DynamoDB
- **Azure**: Functions, Container Apps, Cosmos DB, Service Bus

## Workflow

```
1. Describe feature/component
     ↓
2. Vulcan detects cloud target (or asks)
     ↓
3. Vulcan generates complete C# solution
     ↓
4. Review, adapt, integrate into your project
     ↓
5. Deploy to cloud (if applicable)
```

## Quick Start

1. Seleziona **Vulcan** dal menu agent del tuo coding tool (Claude Code, OpenCode, Copilot, Cursor, Windsurf, Codex)
2. Descrivi cosa vuoi costruire:

```
"Crea un API REST per gestire ordini con validazione e persistenza"
```

Vulcan rileva automaticamente il target cloud e genera tutto il codice necessario.

## Cloud Target Detection

Vulcan automatically detects the cloud target:

### AWS Indicators
- Lambda, SQS, SNS, DynamoDB, S3, Kinesis
- ECS, Fargate, API Gateway
- CloudWatch, X-Ray
- CDK, SAM (Serverless Application Model)

### Azure Indicators
- Azure Functions, Azure Container Apps
- Cosmos DB, Table Storage, Queue Storage
- Service Bus, Event Grid
- Application Insights, Key Vault
- Bicep, Azure Resource Manager

### Generic (No Cloud Specific)
- Local console applications
- Standard .NET libraries
- Generic APIs (HTTP/gRPC)
- Any provider-agnostic pattern

### Manual Target Selection

If target is ambiguous, Vulcan asks:

```
Quale cloud stai usando?
1. AWS
2. Azure
3. Provider-agnostic (generic)
```

Or set environment variable:
```bash
export VULCAN_DEFAULT_CLOUD=aws
```

## Common Workflows

### Workflow 1: Create REST API (Azure)

**Goal**: Build a complete user management API on Azure Functions

**Steps**:

1. **Request code generation**
   ```
   Crea un'API REST per la gestione utenti con:
   - Azure Functions
   - Cosmos DB per persistenza
   - Autenticazione bearer token
   - Logging strutturato
   - Validazione input
   ```

2. **Vulcan generates** (detects Azure automatically):
   ```
   ✓ UserController.cs (Azure Functions HttpTrigger)
   ✓ UserService.cs (business logic)
   ✓ UserRepository.cs (Cosmos DB access)
   ✓ Startup.cs (DI setup)
   ✓ UserValidator.cs (input validation)
   ✓ ErrorHandling.cs (middleware)
   ✓ Logging.cs (Serilog setup)
   ✓ Tests/ (unit test stubs)
   ✓ bicep/ (Infrastructure as Code)
   ```

3. **Integrate into your project**
   ```bash
   cp generated/*.cs ./YourProject/Services/
   cp generated/bicep/ ./YourProject/
   dotnet add package Azure.Identity
   dotnet add package Microsoft.Azure.Cosmos
   ```

4. **Deploy to Azure**
   ```bash
   dotnet build
   az deployment group create --resource-group myRg --template-file bicep/main.bicep
   func azure functionapp publish myFunctionApp
   ```

**Result**: Production-ready Azure Functions API deployed.

---

### Workflow 2: Create Lambda Function (AWS)

**Goal**: Build a serverless data processing function on AWS Lambda

**Steps**:

1. **Request code generation**
   ```
   Crea una Lambda function per processare file CSV:
   - Leggi da S3
   - Valida dati
   - Salva su DynamoDB
   - Logging con CloudWatch
   - Error handling
   ```

2. **Vulcan generates** (detects AWS):
   ```
   ✓ ProcessCsvFunction.cs (Lambda handler)
   ✓ CsvProcessor.cs (processing logic)
   ✓ DynamoDbRepository.cs (data access)
   ✓ Configuration.cs (DI + AWS setup)
   ✓ Validators/ (input validation)
   ✓ Tests/ (unit tests)
   ✓ cdk/ (CDK infrastructure code)
   ✓ sam/ (SAM template)
   ```

3. **Deploy with CDK**
   ```bash
   cdk deploy --all
   # Or with SAM
   sam deploy --guided
   ```

**Result**: Production-ready Lambda function deployed on AWS.

---

### Workflow 3: Refactor Legacy Code

**Goal**: Modernize legacy code to clean architecture

1. **Share existing code and request refactor**
   ```
   Refactor questa classe DataService in architettura pulita
   con Repository Pattern, Dependency Injection e logging:
   
   [paste existing code]
   ```

2. **Vulcan generates**: Interface, Repository, Service, DTOs, Validators, Tests

3. **Integrate incrementally**
   ```bash
   git add -p  # Review changes
   git commit -m "Refactor DataService with Repository Pattern"
   ```

---

### Workflow 4: Create Microservice

**Goal**: Build a complete microservice with API, worker, and shared library

1. **Request scaffold**
   ```
   Crea un microservizio per OrderProcessing:
   - API REST, Worker, Shared library
   - Azure Service Bus, Cosmos DB
   ```

2. **Vulcan generates** multiple projects: `OrderService.API`, `OrderService.Worker`, `OrderService.Domain`, `OrderService.Tests`

3. **Build, test, deploy**
   ```bash
   dotnet build && dotnet test
   az containerapp up --name order-api ...
   ```

---

## Output Structure

By default, Vulcan generates:

```
generated/
├── Controllers/              # HTTP entry points
├── Services/                 # Business logic
├── Data/
│   ├── Repositories/         # Data access
│   └── Entities/             # Domain models
├── Models/
│   ├── Dto/                  # API DTOs
│   ├── Validators/           # FluentValidation
│   └── Exceptions/           # Custom exceptions
├── Infrastructure/
│   ├── DependencyInjection.cs
│   ├── Logging.cs
│   └── Configuration.cs
├── Tests/
│   ├── UnitTests/
│   ├── IntegrationTests/
│   └── Fixtures/
├── [CloudProvider]/          # CDK, Bicep, Terraform
└── Appsettings.json
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

### Cloud Provider Switch

```
// First request (AWS)
"Crea un API per ordini su AWS Lambda"

// Later (switch to Azure)
"Converti lo stesso API per Azure Functions"
```

### Include/Exclude Components

```
"API REST con auth, validation e logging.
 Escludi tests e cloud infrastructure"
```

## Best Practices

✅ **Do**:
- Review generated code before using in production
- Understand the patterns (Repository, DI, async/await)
- Use Vulcan for scaffolding, not black-box generation
- Integrate incrementally into your project

❌ **Don't**:
- Copy-paste generated code without understanding
- Skip testing
- Assume generated code is optimized for your exact needs
- Use production credentials in generated config files
- Deploy without security review

---

**Ready to code?** See **[Examples](./examples.md)** for real-world scenarios.
