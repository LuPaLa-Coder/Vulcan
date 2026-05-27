# Vulcan AWS Templates

Template di riferimento per sviluppo cloud-native su **Amazon Web Services** con C# e .NET 8+.

---

## Boilerplate Lambda Function

### Lambda Minimal (con Lambda Powertools)

```csharp
// src/MyLambda/Function.cs
using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using AWS.Lambda.Powertools.Logging;
using AWS.Lambda.Powertools.Tracing;
using AWS.Lambda.Powertools.Metrics;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace MyLambda;

public class Function
{
    private readonly IMyService _service;

    /// <summary>
    /// Costruttore — client inizializzati qui per riuso tra invocazioni (cold start optimization).
    /// </summary>
    public Function()
    {
        var services = new ServiceCollection();
        Startup.ConfigureServices(services);
        var provider = services.BuildServiceProvider();
        _service = provider.GetRequiredService<IMyService>();
    }

    /// <summary>
    /// Entry point Lambda. Decoratori Powertools abilitano logging strutturato,
    /// X-Ray tracing e CloudWatch metrics automaticamente.
    /// </summary>
    [Logging(LogEvent = true, CorrelationIdPath = CorrelationIdPaths.ApiGatewayRest)]
    [Tracing(CaptureMode = TracingCaptureMode.ResponseAndError)]
    [Metrics(CaptureColdStart = true)]
    public async Task<APIGatewayProxyResponse> FunctionHandler(
        APIGatewayProxyRequest request,
        ILambdaContext context)
    {
        Logger.LogInformation("Processing request {RequestId}", context.AwsRequestId);

        try
        {
            var result = await _service.ProcessAsync(request.Body);

            MetricsLogger.PushSingleMetric("SuccessfulRequests", 1, MetricUnit.Count);

            return new APIGatewayProxyResponse
            {
                StatusCode = 200,
                Headers = new Dictionary<string, string> { ["Content-Type"] = "application/json" },
                Body = JsonSerializer.Serialize(result)
            };
        }
        catch (ValidationException ex)
        {
            Logger.LogWarning(ex, "Validation failed");
            return new APIGatewayProxyResponse
            {
                StatusCode = 400,
                Body = JsonSerializer.Serialize(new { error = ex.Message })
            };
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Unhandled exception");
            MetricsLogger.PushSingleMetric("FailedRequests", 1, MetricUnit.Count);
            return new APIGatewayProxyResponse
            {
                StatusCode = 500,
                Body = JsonSerializer.Serialize(new { error = "Internal server error" })
            };
        }
    }
}
```

---

## Startup con Dependency Injection

```csharp
// src/MyLambda/Startup.cs
using Amazon.DynamoDBv2;
using Amazon.S3;
using Amazon.SQS;
using Amazon.SecretsManager;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Serilog;
using Serilog.Formatting.Json;

namespace MyLambda;

public static class Startup
{
    /// <summary>
    /// Registra tutti i servizi AWS e applicativi nel container DI.
    /// Chiamato una volta sola durante il cold start Lambda.
    /// </summary>
    public static void ConfigureServices(IServiceCollection services)
    {
        // --- Configurazione ---
        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        services.AddSingleton<IConfiguration>(configuration);

        // --- Serilog (structured logging verso CloudWatch) ---
        Log.Logger = new LoggerConfiguration()
            .Enrich.FromLogContext()
            .Enrich.WithProperty("Service", "MyLambda")
            .WriteTo.Console(new JsonFormatter())
            .MinimumLevel.Information()
            .CreateLogger();

        services.AddLogging(b => b.AddSerilog(Log.Logger, dispose: true));

        // --- AWS SDK clients (singleton per riuso connessioni) ---
        services.AddSingleton<IAmazonDynamoDB, AmazonDynamoDBClient>();
        services.AddSingleton<IAmazonS3, AmazonS3Client>();
        services.AddSingleton<IAmazonSQS, AmazonSQSClient>();
        services.AddSingleton<IAmazonSecretsManager, AmazonSecretsManagerClient>();

        // --- Options ---
        services.Configure<AppOptions>(configuration.GetSection("App"));

        // --- Repository ---
        services.AddSingleton<IMyRepository, DynamoDbMyRepository>();

        // --- Services ---
        services.AddTransient<IMyService, MyService>();

        // --- Polly resilience (retry + circuit breaker) ---
        services.AddHttpClient<IExternalApiClient, ExternalApiClient>()
            .AddPolicyHandler(ResiliencePolicies.GetRetryPolicy())
            .AddPolicyHandler(ResiliencePolicies.GetCircuitBreakerPolicy());
    }
}
```

```csharp
// src/MyLambda/Infrastructure/ResiliencePolicies.cs
using Polly;
using Polly.Extensions.Http;

namespace MyLambda.Infrastructure;

/// <summary>
/// Policy Polly con exponential backoff + jitter e circuit breaker.
/// </summary>
public static class ResiliencePolicies
{
    public static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy() =>
        HttpPolicyExtensions
            .HandleTransientHttpError()
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: attempt =>
                    TimeSpan.FromSeconds(Math.Pow(2, attempt)) +
                    TimeSpan.FromMilliseconds(Random.Shared.Next(0, 100)));

    public static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy() =>
        HttpPolicyExtensions
            .HandleTransientHttpError()
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5,
                durationOfBreak: TimeSpan.FromSeconds(30));
}
```

---

## Repository DynamoDB

```csharp
// src/MyLambda/Data/DynamoDbMyRepository.cs
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Serilog;

namespace MyLambda.Data;

/// <summary>
/// Repository DynamoDB con DynamoDB Object Persistence Model.
/// </summary>
public sealed class DynamoDbMyRepository : IMyRepository
{
    private readonly IDynamoDBContext _context;
    private readonly ILogger<DynamoDbMyRepository> _logger;

    public DynamoDbMyRepository(IAmazonDynamoDB client, ILogger<DynamoDbMyRepository> logger)
    {
        _context = new DynamoDBContext(client);
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<MyEntity?> GetByIdAsync(string id, CancellationToken ct = default)
    {
        _logger.LogInformation("Fetching entity {Id}", id);
        return await _context.LoadAsync<MyEntity>(id, ct);
    }

    /// <inheritdoc />
    public async Task SaveAsync(MyEntity entity, CancellationToken ct = default)
    {
        _logger.LogInformation("Saving entity {Id}", entity.Id);
        await _context.SaveAsync(entity, ct);
    }

    /// <inheritdoc />
    public async Task DeleteAsync(string id, CancellationToken ct = default)
    {
        _logger.LogInformation("Deleting entity {Id}", id);
        await _context.DeleteAsync<MyEntity>(id, ct);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<MyEntity>> QueryByPartitionAsync(
        string partitionKey,
        CancellationToken ct = default)
    {
        var conditions = new List<ScanCondition>();
        var results = await _context.QueryAsync<MyEntity>(partitionKey).GetRemainingAsync(ct);
        return results.AsReadOnly();
    }
}

[DynamoDBTable("MyEntities")]
public class MyEntity
{
    [DynamoDBHashKey]
    public string Id { get; set; } = default!;

    [DynamoDBRangeKey]
    public string SortKey { get; set; } = default!;

    public string Data { get; set; } = default!;

    [DynamoDBProperty]
    public DateTime CreatedAt { get; set; }

    [DynamoDBVersion]
    public int? Version { get; set; }
}
```

---

## SQS Worker (event-driven)

```csharp
// src/MyWorker/SqsWorkerFunction.cs
using Amazon.Lambda.SQSEvents;
using AWS.Lambda.Powertools.Logging;
using AWS.Lambda.Powertools.Tracing;

namespace MyWorker;

public class SqsWorkerFunction
{
    private readonly IMessageProcessor _processor;

    public SqsWorkerFunction()
    {
        var services = new ServiceCollection();
        Startup.ConfigureServices(services);
        _processor = services.BuildServiceProvider()
            .GetRequiredService<IMessageProcessor>();
    }

    [Logging(LogEvent = true)]
    [Tracing]
    public async Task<SQSBatchResponse> FunctionHandler(SQSEvent sqsEvent)
    {
        var batchItemFailures = new List<SQSBatchResponse.BatchItemFailure>();

        foreach (var record in sqsEvent.Records)
        {
            try
            {
                Logger.LogInformation("Processing message {MessageId}", record.MessageId);
                await _processor.ProcessAsync(record.Body);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Failed to process message {MessageId}", record.MessageId);
                // Segnala il fallimento per partial batch response → messaggio va in DLQ
                batchItemFailures.Add(new SQSBatchResponse.BatchItemFailure
                {
                    ItemIdentifier = record.MessageId
                });
            }
        }

        return new SQSBatchResponse { BatchItemFailures = batchItemFailures };
    }
}
```

---

## AWS CDK Stack (C#)

### Stack completo: Lambda + API Gateway + DynamoDB + SQS + DLQ

```csharp
// cdk/src/MyCdkApp/MyServiceStack.cs
using Amazon.CDK;
using Amazon.CDK.AWS.APIGateway;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Logs;
using Amazon.CDK.AWS.SQS;
using Amazon.CDK.AWS.Lambda.EventSources;
using Constructs;

namespace MyCdkApp;

public class MyServiceStack : Stack
{
    /// <summary>
    /// Stack CDK completo: Lambda + API Gateway REST + DynamoDB + SQS + DLQ.
    /// </summary>
    public MyServiceStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        // --- DynamoDB Table ---
        var table = new Table(this, "MyTable", new TableProps
        {
            TableName = "MyEntities",
            PartitionKey = new Attribute { Name = "Id", Type = AttributeType.STRING },
            SortKey = new Attribute { Name = "SortKey", Type = AttributeType.STRING },
            BillingMode = BillingMode.PAY_PER_REQUEST,
            PointInTimeRecovery = true,
            RemovalPolicy = RemovalPolicy.RETAIN,
            Encryption = TableEncryption.AWS_MANAGED
        });

        // --- Dead Letter Queue ---
        var dlq = new Queue(this, "MyDlq", new QueueProps
        {
            QueueName = "my-service-dlq",
            RetentionPeriod = Duration.Days(14),
            Encryption = QueueEncryption.KMS_MANAGED
        });

        // --- SQS Queue ---
        var queue = new Queue(this, "MyQueue", new QueueProps
        {
            QueueName = "my-service-queue",
            VisibilityTimeout = Duration.Seconds(300),
            DeadLetterQueue = new DeadLetterQueue
            {
                Queue = dlq,
                MaxReceiveCount = 3
            },
            Encryption = QueueEncryption.KMS_MANAGED
        });

        // --- IAM Role (least privilege) ---
        var lambdaRole = new Role(this, "LambdaRole", new RoleProps
        {
            AssumedBy = new ServicePrincipal("lambda.amazonaws.com"),
            ManagedPolicies = new[]
            {
                ManagedPolicy.FromAwsManagedPolicyName("service-role/AWSLambdaBasicExecutionRole"),
                ManagedPolicy.FromAwsManagedPolicyName("AWSXRayDaemonWriteAccess")
            }
        });

        table.GrantReadWriteData(lambdaRole);
        queue.GrantConsumeMessages(lambdaRole);

        // --- Lambda Layer (dipendenze condivise) ---
        var commonLayer = new LayerVersion(this, "CommonLayer", new LayerVersionProps
        {
            Code = Code.FromAsset("src/layers/common"),
            CompatibleRuntimes = new[] { Runtime.DOTNET_8 },
            Description = "Common dependencies layer"
        });

        // --- Lambda Function (HTTP handler) ---
        var httpFunction = new Function(this, "HttpFunction", new FunctionProps
        {
            FunctionName = "my-service-http",
            Runtime = Runtime.DOTNET_8,
            Handler = "MyLambda::MyLambda.Function::FunctionHandler",
            Code = Code.FromAsset("src/MyLambda/bin/Release/net8.0"),
            Role = lambdaRole,
            Timeout = Duration.Seconds(30),
            MemorySize = 512,
            Tracing = Tracing.ACTIVE,
            Layers = new[] { commonLayer },
            Environment = new Dictionary<string, string>
            {
                ["TABLE_NAME"] = table.TableName,
                ["QUEUE_URL"] = queue.QueueUrl,
                ["POWERTOOLS_SERVICE_NAME"] = "my-service",
                ["POWERTOOLS_LOG_LEVEL"] = "INFO",
                ["POWERTOOLS_METRICS_NAMESPACE"] = "MyService"
            },
            LogRetention = RetentionDays.ONE_MONTH,
            DeadLetterQueue = dlq
        });

        // --- Lambda Function (SQS worker) ---
        var workerFunction = new Function(this, "WorkerFunction", new FunctionProps
        {
            FunctionName = "my-service-worker",
            Runtime = Runtime.DOTNET_8,
            Handler = "MyWorker::MyWorker.SqsWorkerFunction::FunctionHandler",
            Code = Code.FromAsset("src/MyWorker/bin/Release/net8.0"),
            Role = lambdaRole,
            Timeout = Duration.Seconds(300),
            MemorySize = 256,
            Tracing = Tracing.ACTIVE,
            ReservedConcurrentExecutions = 10,
            Environment = new Dictionary<string, string>
            {
                ["TABLE_NAME"] = table.TableName,
                ["POWERTOOLS_SERVICE_NAME"] = "my-service-worker"
            }
        });

        workerFunction.AddEventSource(new SqsEventSource(queue, new SqsEventSourceProps
        {
            BatchSize = 10,
            MaxBatchingWindow = Duration.Seconds(30),
            ReportBatchItemFailures = true // Partial batch response
        }));

        // --- API Gateway REST ---
        var api = new RestApi(this, "MyApi", new RestApiProps
        {
            RestApiName = "my-service-api",
            DeployOptions = new StageOptions
            {
                StageName = "prod",
                TracingEnabled = true,
                DataTraceEnabled = false, // solo in dev
                LoggingLevel = MethodLoggingLevel.ERROR,
                MetricsEnabled = true,
                ThrottlingBurstLimit = 1000,
                ThrottlingRateLimit = 500
            },
            DefaultCorsPreflightOptions = new CorsOptions
            {
                AllowOrigins = Cors.ALL_ORIGINS,
                AllowMethods = Cors.ALL_METHODS
            }
        });

        var integration = new LambdaIntegration(httpFunction, new LambdaIntegrationOptions
        {
            Proxy = true
        });

        var items = api.Root.AddResource("items");
        items.AddMethod("GET", integration);
        items.AddMethod("POST", integration);

        var item = items.AddResource("{id}");
        item.AddMethod("GET", integration);
        item.AddMethod("PUT", integration);
        item.AddMethod("DELETE", integration);

        // --- CloudFormation Outputs ---
        _ = new CfnOutput(this, "ApiUrl", new CfnOutputProps
        {
            Value = api.Url,
            Description = "API Gateway URL"
        });

        _ = new CfnOutput(this, "TableName", new CfnOutputProps
        {
            Value = table.TableName,
            Description = "DynamoDB Table Name"
        });

        _ = new CfnOutput(this, "QueueUrl", new CfnOutputProps
        {
            Value = queue.QueueUrl,
            Description = "SQS Queue URL"
        });
    }
}
```

### CDK App Entry Point

```csharp
// cdk/src/MyCdkApp/Program.cs
using Amazon.CDK;
using MyCdkApp;

var app = new App();

new MyServiceStack(app, "MyServiceStack-Dev", new StackProps
{
    Env = new Amazon.CDK.Environment
    {
        Account = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_ACCOUNT"),
        Region = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_REGION") ?? "eu-west-1"
    },
    Tags = new Dictionary<string, string>
    {
        ["Environment"] = "dev",
        ["Project"] = "my-service",
        ["ManagedBy"] = "CDK"
    }
});

app.Synth();
```

---

## SAM Template

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Description: My Service — Lambda + API Gateway + DynamoDB

Globals:
  Function:
    Runtime: dotnet8
    Timeout: 30
    MemorySize: 512
    Tracing: Active
    Environment:
      Variables:
        POWERTOOLS_SERVICE_NAME: my-service
        POWERTOOLS_LOG_LEVEL: INFO
        POWERTOOLS_METRICS_NAMESPACE: MyService

Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]

Resources:
  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub "MyEntities-${Environment}"
      BillingMode: PAY_PER_REQUEST
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true
      SSESpecification:
        SSEEnabled: true
      AttributeDefinitions:
        - AttributeName: Id
          AttributeType: S
        - AttributeName: SortKey
          AttributeType: S
      KeySchema:
        - AttributeName: Id
          KeyType: HASH
        - AttributeName: SortKey
          KeyType: RANGE

  MyDlq:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub "my-service-dlq-${Environment}"
      MessageRetentionPeriod: 1209600  # 14 days

  MyQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub "my-service-queue-${Environment}"
      VisibilityTimeout: 300
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt MyDlq.Arn
        maxReceiveCount: 3

  HttpFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub "my-service-http-${Environment}"
      Handler: MyLambda::MyLambda.Function::FunctionHandler
      CodeUri: src/MyLambda/
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref MyTable
        - SQSSendMessagePolicy:
            QueueName: !GetAtt MyQueue.QueueName
      Environment:
        Variables:
          TABLE_NAME: !Ref MyTable
          QUEUE_URL: !Ref MyQueue
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /items/{proxy+}
            Method: ANY

  WorkerFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: !Sub "my-service-worker-${Environment}"
      Handler: MyWorker::MyWorker.SqsWorkerFunction::FunctionHandler
      CodeUri: src/MyWorker/
      Timeout: 300
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref MyTable
        - SQSPollerPolicy:
            QueueName: !GetAtt MyQueue.QueueName
      Events:
        SqsEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt MyQueue.Arn
            BatchSize: 10
            FunctionResponseTypes:
              - ReportBatchItemFailures

Outputs:
  ApiUrl:
    Description: API Gateway URL
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/"
  TableName:
    Description: DynamoDB Table Name
    Value: !Ref MyTable
```

---

## docker-compose.yml con LocalStack

```yaml
# docker-compose.yml
version: "3.8"

services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=dynamodb,s3,sqs,secretsmanager,lambda
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
      - LAMBDA_EXECUTOR=docker
      - DOCKER_HOST=unix:///var/run/docker.sock
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./localstack/init:/docker-entrypoint-initaws.d"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4566/_localstack/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      localstack:
        condition: service_healthy
    environment:
      - AWS_ACCESS_KEY_ID=test
      - AWS_SECRET_ACCESS_KEY=test
      - AWS_DEFAULT_REGION=us-east-1
      - AWS_ENDPOINT_URL=http://localstack:4566
      - TABLE_NAME=MyEntities
      - QUEUE_URL=http://localstack:4566/000000000000/my-service-queue
```

```bash
# localstack/init/01-setup.sh
#!/bin/bash
# Inizializzazione LocalStack per sviluppo locale

echo "Setting up LocalStack resources..."

# DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
  --table-name MyEntities \
  --attribute-definitions \
    AttributeName=Id,AttributeType=S \
    AttributeName=SortKey,AttributeType=S \
  --key-schema \
    AttributeName=Id,KeyType=HASH \
    AttributeName=SortKey,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

# SQS
aws --endpoint-url=http://localhost:4566 sqs create-queue \
  --queue-name my-service-dlq

aws --endpoint-url=http://localhost:4566 sqs create-queue \
  --queue-name my-service-queue \
  --attributes '{"RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:my-service-dlq\",\"maxReceiveCount\":\"3\"}"}'

# S3
aws --endpoint-url=http://localhost:4566 s3 mb s3://my-service-bucket

echo "LocalStack setup complete."
```

---

## Dockerfile multi-stage Lambda

```dockerfile
# Dockerfile (Lambda Container Image)
FROM public.ecr.aws/lambda/dotnet:8 AS base
WORKDIR /var/task

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/MyLambda/MyLambda.csproj", "MyLambda/"]
RUN dotnet restore "MyLambda/MyLambda.csproj"

COPY src/MyLambda/ MyLambda/
WORKDIR /src/MyLambda
RUN dotnet publish -c Release -o /app/publish \
    --no-restore \
    -p:PublishReadyToRun=true

FROM base AS final
COPY --from=build /app/publish ${LAMBDA_TASK_ROOT}
CMD ["MyLambda::MyLambda.Function::FunctionHandler"]
```

---

## CI/CD — GitHub Actions

```yaml
# .github/workflows/deploy-aws.yml
name: Deploy to AWS

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: eu-west-1
  DOTNET_VERSION: 8.0.x

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore -c Release

      - name: Test
        run: dotnet test --no-build -c Release --verbosity normal \
          --collect "Code Coverage" \
          --results-directory ./coverage

      - name: Security scan (no hardcoded secrets)
        run: |
          if grep -rn "aws_access_key_id\|aws_secret_access_key\|AKIA" \
            --include="*.cs" --include="*.json" --include="*.yml" \
            --exclude-dir=".git" .; then
            echo "BLOCKER: Hardcoded AWS credentials found"
            exit 1
          fi

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Install CDK
        run: npm install -g aws-cdk

      - name: Build Lambda artifacts
        run: |
          dotnet publish src/MyLambda -c Release -o dist/MyLambda
          dotnet publish src/MyWorker -c Release -o dist/MyWorker

      - name: CDK Deploy
        working-directory: cdk
        run: |
          dotnet restore
          cdk deploy --require-approval never --all
```

---

## Well-Architected Framework — 5 Pilastri per AWS

### 1. Operational Excellence

```markdown
**Principi**:
- Infrastructure as Code (CDK o SAM) — mai provisioning manuale
- CI/CD automatizzato (GitHub Actions, CodePipeline)
- Observability: Lambda Powertools [Logging] + [Tracing] + [Metrics]
- Runbook documentati per ogni scenario di failure

**Pattern**:
- Strutturato logging JSON → CloudWatch Logs Insights
- Distributed tracing → X-Ray + Service Map
- Custom metrics → CloudWatch Dashboards
- Alerts → CloudWatch Alarms → SNS → PagerDuty/Slack
```

### 2. Security

```markdown
**Principi**:
- IAM least privilege: ogni Lambda ha il suo Role con solo le permission necessarie
- Secrets Manager per tutti i segreti (no env var per credenziali sensibili)
- KMS encryption at-rest (DynamoDB, S3, SQS)
- TLS in-transit su tutti gli endpoint
- VPC + Security Groups per risorse non pubbliche

**Checklist**:
- [ ] Nessun access key hardcoded nel codice
- [ ] IAM Role con policy custom (no AdministratorAccess)
- [ ] Secrets rotation automatica in Secrets Manager
- [ ] CloudTrail abilitato
- [ ] GuardDuty abilitato
- [ ] AWS WAF su API Gateway (prod)
- [ ] S3 bucket policy: block public access
```

### 3. Reliability

```markdown
**Principi**:
- Multi-AZ deployment per tutti i servizi managed
- DLQ su ogni Lambda e SQS consumer
- Retry + exponential backoff + jitter (Polly)
- Circuit breaker per chiamate a servizi esterni
- Graceful degradation: fallback se servizio non disponibile

**Pattern**:
- SQS partial batch response (ReportBatchItemFailures)
- DynamoDB conditional writes per concorrenza ottimistica
- S3 versioning su bucket critici
- RDS Aurora Multi-AZ (se relazionale necessario)
- Health check endpoint per ogni servizio
```

### 4. Performance Efficiency

```markdown
**Principi**:
- Lambda: memoria sizing con AWS Lambda Power Tuning
- Cold start optimization: client SDK fuori dall'handler
- DynamoDB: query invece di scan, GSI per access pattern secondari
- Caching: ElastiCache Redis o DynamoDB DAX per hot data
- Provisioned Concurrency per Lambda critici a bassa latenza

**Metriche target**:
- Lambda P99 < 3s (HTTP handlers)
- DynamoDB P99 < 10ms (single item get)
- API Gateway P99 < 500ms
- Cold start < 2s con SnapStart o Provisioned Concurrency
```

### 5. Cost Optimization

```markdown
**Principi**:
- DynamoDB on-demand per carichi variabili; provisioned + auto-scaling per baseline stabile
- Lambda pay-per-use: nessun costo quando idle
- S3 lifecycle policies: transizione a IA dopo 30gg, Glacier dopo 90gg
- CloudWatch Log retention: 30gg dev, 90gg prod (non infinite)
- Reserved Instances o Savings Plans per ECS/RDS se carichi prevedibili

**Cost Explorer tags obbligatori**:
- Environment: dev | staging | prod
- Project: <nome>
- ManagedBy: CDK | SAM | Terraform

**Stima costi Lambda (baseline)**:
- 1M invocazioni/mese, 512MB, 500ms avg → ~$4/mese
- DynamoDB on-demand, 1M writes + 10M reads → ~$1.4/mese
- SQS: 1M messaggi/mese → ~$0.40/mese
```

---

## IAM Policy — Esempio Least Privilege

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:BatchWriteItem",
        "dynamodb:BatchGetItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:eu-west-1:123456789:table/MyEntities",
        "arn:aws:dynamodb:eu-west-1:123456789:table/MyEntities/index/*"
      ]
    },
    {
      "Sid": "SQSConsumer",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:eu-west-1:123456789:my-service-queue"
    },
    {
      "Sid": "SecretsManagerRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:eu-west-1:123456789:secret:my-service/*"
    },
    {
      "Sid": "XRayWrite",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## appsettings.json (Lambda)

```json
{
  "App": {
    "ServiceName": "my-service",
    "Environment": "dev"
  },
  "AWS": {
    "Region": "eu-west-1"
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning",
        "Amazon": "Warning"
      }
    }
  }
}
```

---

## Riferimenti

- [Lambda Powertools for .NET](https://docs.powertools.aws.dev/lambda/dotnet/)
- [AWS CDK for .NET](https://docs.aws.amazon.com/cdk/v2/guide/work-with-cdk-csharp.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS SDK for .NET](https://docs.aws.amazon.com/sdk-for-net/)
- [LocalStack](https://docs.localstack.cloud/)
