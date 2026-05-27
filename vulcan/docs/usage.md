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

## Basic Commands

### Start Code Generation

**Interactive (Copilot CLI)**
```
copilot
/agent
# Select: Vulcan

"Crea un API REST per gestire ordini con validazione e persistenza"
```

**Input File**
```bash
cat > code-request.json << 'EOF'
{
  "feature": "REST API for user management",
  "appType": "API",
  "storage": "Cosmos DB",
  "target": "Azure",
  "framework": "net8"
}
EOF

copilot /agent Vulcan < code-request.json
```

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
🤔 Quale cloud stai usando?
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
   # Copy files
   cp generated/*.cs ./YourProject/Services/
   cp generated/bicep/ ./YourProject/
   
   # Update appsettings
   dotnet add package Azure.Identity
   dotnet add package Microsoft.Azure.Cosmos
   ```

4. **Deploy to Azure**
   ```bash
   # Build
   dotnet build
   
   # Deploy infrastructure
   az deployment group create \
     --resource-group myRg \
     --template-file bicep/main.bicep
   
   # Deploy code
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

3. **Integrate and test locally**
   ```bash
   # Install SAM CLI
   pip install aws-sam-cli
   
   # Copy generated code
   cp -r generated/* ./lambda-project/
   
   # Test locally
   sam local start-api
   
   # Invoke locally
   sam local invoke ProcessCsvFunction \
     -e events/s3-event.json
   ```

4. **Deploy with CDK**
   ```bash
   # Deploy infrastructure + code
   cdk deploy --all
   
   # Or with SAM
   sam deploy --guided
   ```

**Result**: Production-ready Lambda function deployed on AWS.

---

### Workflow 3: Refactor Legacy Code

**Goal**: Modernize legacy ASP.NET code to modern .NET 8 with clean architecture

**Steps**:

1. **Share existing code section**
   ```
   Refactor questa classe DataService in architettura pulita
   con Repository Pattern, Dependency Injection e logging:
   
   [paste existing code]
   ```

2. **Vulcan analyzes and generates**
   ```
   ✓ IDataRepository.cs (interface)
   ✓ DataRepository.cs (implementation)
   ✓ DataService.cs (refactored business logic)
   ✓ Mapper.cs (DTOs if needed)
   ✓ Logger setup
   ✓ Error handling patterns
   ✓ Tests with mocks
   ```

3. **Review and integrate**
   - Compare old vs. new
   - Adjust mapping if needed
   - Update DI container
   - Run tests

4. **Commit incrementally**
   ```bash
   git add -p  # Review changes
   git commit -m "Refactor DataService with Repository Pattern"
   ```

**Result**: Modernized, testable code.

---

### Workflow 4: Create Microservice

**Goal**: Build a complete microservice with API, worker, and shared library

**Steps**:

1. **Request microservice scaffold**
   ```
   Crea una microservizio completa per OrderProcessing:
   - API REST (create, read, update orders)
   - Worker (process payment async)
   - Shared library (domain models, DTOs)
   - Azure Service Bus integration
   - Cosmos DB persistence
   ```

2. **Vulcan generates** (multiple projects):
   ```
   OrderService.API/
   ├── Controllers/OrderController.cs
   ├── Services/OrderService.cs
   └── DependencyInjection.cs
   
   OrderService.Worker/
   ├── PaymentProcessor.cs
   ├── ServiceBusListener.cs
   └── Startup.cs
   
   OrderService.Domain/
   ├── Models/Order.cs
   ├── DTOs/OrderDto.cs
   └── Validators/
   
   OrderService.Tests/
   ├── ServiceTests/
   └── IntegrationTests/
   ```

3. **Build and test**
   ```bash
   dotnet build
   dotnet test
   
   # Run API
   dotnet run --project OrderService.API
   
   # In another terminal, run worker
   dotnet run --project OrderService.Worker
   ```

4. **Deploy both services**
   ```bash
   # Deploy API to Container Apps
   az containerapp up --name order-api ...
   
   # Deploy Worker to Container Apps
   az containerapp up --name order-worker ...
   ```

**Result**: Fully integrated microservice architecture.

---

## Output Structure

By default, Vulcan generates:

```
generated/
├── Controllers/              # HTTP entry points
│   └── *.cs
├── Services/                 # Business logic
│   └── *.cs
├── Data/
│   ├── Repositories/         # Data access
│   └── Entities/             # EF models
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
├── [CloudProvider]/          # AWS CDK, Azure Bicep, etc.
│   └── *.cs (or .bicep, .tf)
└── Appsettings.json         # Configuration template
```

## Advanced Usage

### Custom Project Structure

Request specific project layout:

```
Voglio una struttura multi-layer con:
- Core (business logic)
- Application (use cases)
- Infrastructure (data, cloud)
- Presentation (API)
```

Vulcan adjusts the generated structure accordingly.

### Cloud Provider Switch

Change target cloud for same feature:

```
// First request (AWS)
"Crea un API per ordini su AWS Lambda"

// Later (switch to Azure)
"Converti lo stesso API per Azure Functions"
```

Vulcan translates patterns accordingly.

### Include/Exclude Components

Control what gets generated:

```
"API REST con autenticazione, validation e logging.
 Escludi tests e cloud infrastructure (farò io dopo)"
```

## Troubleshooting

### "Generated code doesn't compile"
- Check .NET version: `dotnet --version`
- Run `dotnet restore` to fetch NuGet packages
- Review error messages for missing dependencies
- Check [examples.md](./examples.md) for similar code

### "Ambiguous cloud target"
- Set `VULCAN_DEFAULT_CLOUD` environment variable
- Or Vulcan asks clarifying question (answer one of: AWS, Azure, generic)

### "Generated API can't connect to database"
- Verify connection string in appsettings.json
- Ensure database/service exists in your subscription/account
- Check authentication credentials (IAM, RBAC, connection string)
- Review example in [examples.md](./examples.md)

### "Tests don't run"
- Ensure test project has correct target framework
- Install testing NuGet packages (xUnit, Moq, etc.)
- Use `dotnet test --verbosity detailed` for diagnostics
- Review test example in [examples.md](./examples.md)

## Best Practices

✅ **Do**:
- Review generated code before using in production
- Understand the patterns (Repository, DI, async/await)
- Add unit tests for business logic
- Use Vulcan for scaffolding, not black-box generation
- Integrate incrementally into your project

❌ **Don't**:
- Copy-paste generated code without understanding
- Skip testing ("I'll test later")
- Assume generated code is optimized for your exact needs
- Use production credentials in generated config files
- Deploy without security review

## Support

For issues or questions:
1. Check **[Examples](./examples.md)** for similar scenarios
2. Review **[Installation Guide](./installation.md)** for setup help
3. Enable verbose logging in generated code
4. Review main [README](./README.md)

---

**Ready to code?** See **[Examples](./examples.md)** for real-world scenarios.
