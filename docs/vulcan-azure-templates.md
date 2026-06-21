# Vulcan Azure Templates

Template di riferimento per sviluppo cloud-native su **Microsoft Azure** con C# e .NET 8+.

---

## Boilerplate Azure Function (Isolated Worker)

### HTTP Trigger

```csharp
// src/MyFunction/HttpTriggerFunction.cs
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

namespace MyFunction;

/// <summary>
/// HTTP Trigger con autenticazione, validazione, logging strutturato e error handling.
/// </summary>
public sealed class HttpTriggerFunction
{
    private readonly IMyService _service;
    private readonly ILogger<HttpTriggerFunction> _logger;

    public HttpTriggerFunction(IMyService service, ILogger<HttpTriggerFunction> logger)
    {
        _service = service;
        _logger = logger;
    }

    /// <summary>
    /// Endpoint GET /api/items — restituisce lista paginata.
    /// </summary>
    [Function(nameof(GetItems))]
    public async Task<HttpResponseData> GetItems(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "items")] HttpRequestData req,
        FunctionContext context)
    {
        _logger.LogInformation("GetItems called. InvocationId={InvocationId}", context.InvocationId);

        try
        {
            var top = int.TryParse(req.Query["top"], out var t) ? t : 20;
            var skip = int.TryParse(req.Query["skip"], out var s) ? s : 0;

            var result = await _service.GetItemsAsync(top, skip);

            var response = req.CreateResponse(HttpStatusCode.OK);
            await response.WriteAsJsonAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception in GetItems");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { error = "Internal server error" });
            return response;
        }
    }

    /// <summary>
    /// Endpoint POST /api/items — crea un nuovo item con validazione.
    /// </summary>
    [Function(nameof(CreateItem))]
    public async Task<HttpResponseData> CreateItem(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "items")] HttpRequestData req,
        FunctionContext context)
    {
        _logger.LogInformation("CreateItem called. InvocationId={InvocationId}", context.InvocationId);

        try
        {
            var dto = await req.ReadFromJsonAsync<CreateItemDto>()
                ?? throw new ArgumentNullException("Request body is required");

            var created = await _service.CreateAsync(dto);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Location", $"/api/items/{created.Id}");
            await response.WriteAsJsonAsync(created);
            return response;
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(ex, "Validation failed");
            var response = req.CreateResponse(HttpStatusCode.BadRequest);
            await response.WriteAsJsonAsync(new { error = ex.Message, details = ex.Errors });
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception in CreateItem");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteAsJsonAsync(new { error = "Internal server error" });
            return response;
        }
    }
}
```

### Service Bus Trigger

```csharp
// src/MyFunction/ServiceBusTriggerFunction.cs
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace MyFunction;

/// <summary>
/// Service Bus Trigger — processa messaggi con retry automatico e dead-letter su failure.
/// </summary>
public sealed class ServiceBusTriggerFunction
{
    private readonly IMessageProcessor _processor;
    private readonly ILogger<ServiceBusTriggerFunction> _logger;

    public ServiceBusTriggerFunction(IMessageProcessor processor, ILogger<ServiceBusTriggerFunction> logger)
    {
        _processor = processor;
        _logger = logger;
    }

    /// <summary>
    /// Processa messaggi dalla coda. In caso di eccezione, il messaggio viene
    /// abbandonato (abandon) e dopo maxDeliveryCount va in dead-letter.
    /// </summary>
    [Function(nameof(ProcessMessage))]
    public async Task ProcessMessage(
        [ServiceBusTrigger("my-queue", Connection = "ServiceBus:ConnectionString")] string messageBody,
        string messageId,
        FunctionContext context)
    {
        _logger.LogInformation(
            "Processing message {MessageId}. InvocationId={InvocationId}",
            messageId, context.InvocationId);

        await _processor.ProcessAsync(messageBody);

        _logger.LogInformation("Message {MessageId} processed successfully", messageId);
    }
}
```

### Timer Trigger

```csharp
// src/MyFunction/TimerTriggerFunction.cs
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace MyFunction;

/// <summary>
/// Timer Trigger — eseguito ogni ora. Usa NCRONTAB expression.
/// </summary>
public sealed class TimerTriggerFunction
{
    private readonly ICleanupService _cleanupService;
    private readonly ILogger<TimerTriggerFunction> _logger;

    public TimerTriggerFunction(ICleanupService cleanupService, ILogger<TimerTriggerFunction> logger)
    {
        _cleanupService = cleanupService;
        _logger = logger;
    }

    /// <summary>
    /// Cleanup schedulato: corre ogni ora.
    /// NCRONTAB: "0 */1 * * *" = ogni ora al minuto 0.
    /// </summary>
    [Function(nameof(HourlyCleanup))]
    public async Task HourlyCleanup(
        [TimerTrigger("0 */1 * * *")] TimerInfo timerInfo,
        FunctionContext context)
    {
        if (timerInfo.ScheduleStatus is not null)
        {
            _logger.LogInformation(
                "Timer triggered. Last: {Last}, Next: {Next}",
                timerInfo.ScheduleStatus.Last,
                timerInfo.ScheduleStatus.Next);
        }

        await _cleanupService.RunAsync();
    }
}
```

---

## Startup con tutti i Servizi Azure

```csharp
// src/MyFunction/Program.cs
using Azure.Identity;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using Serilog.Sinks.ApplicationInsights.TelemetryConverters;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration(config =>
    {
        config.AddEnvironmentVariables();
        // App Configuration (feature flags, config centralizzata)
        var appConfigEndpoint = Environment.GetEnvironmentVariable("AppConfiguration:Endpoint");
        if (!string.IsNullOrEmpty(appConfigEndpoint))
        {
            config.AddAzureAppConfiguration(options =>
                options
                    .Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential())
                    .UseFeatureFlags());
        }
    })
    .ConfigureServices((context, services) =>
    {
        var configuration = context.Configuration;

        // --- Serilog → Application Insights ---
        Log.Logger = new LoggerConfiguration()
            .Enrich.FromLogContext()
            .Enrich.WithProperty("Service", "my-function")
            .Enrich.WithProperty("Environment", context.HostingEnvironment.EnvironmentName)
            .WriteTo.Console()
            .WriteTo.ApplicationInsights(
                configuration["ApplicationInsights:ConnectionString"],
                new TraceTelemetryConverter())
            .MinimumLevel.Information()
            .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Warning)
            .CreateLogger();

        services.AddLogging(b => b.AddSerilog(Log.Logger, dispose: true));

        // --- Azure Clients (DefaultAzureCredential unificato) ---
        services.AddAzureClients(clientBuilder =>
        {
            clientBuilder.UseCredential(new DefaultAzureCredential());

            // Key Vault Secrets
            clientBuilder.AddSecretClient(
                new Uri(configuration["KeyVault:Url"]!));

            // Service Bus
            clientBuilder.AddServiceBusClientWithNamespace(
                configuration["ServiceBus:Namespace"]!);

            // Blob Storage
            clientBuilder.AddBlobServiceClient(
                new Uri(configuration["Storage:BlobEndpoint"]!));

            // Event Grid
            clientBuilder.AddEventGridPublisherClient(
                new Uri(configuration["EventGrid:TopicEndpoint"]!));
        });

        // --- Cosmos DB (client singleton per riuso connessioni) ---
        services.AddSingleton(sp =>
        {
            var endpoint = configuration["CosmosDb:Endpoint"]!;
            return new CosmosClient(endpoint, new DefaultAzureCredential(), new CosmosClientOptions
            {
                SerializerOptions = new CosmosSerializationOptions
                {
                    PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
                },
                ConnectionMode = ConnectionMode.Direct,
                MaxRetryAttemptsOnRateLimitedRequests = 9,
                MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(30)
            });
        });

        // --- Application Insights ---
        services.AddApplicationInsightsTelemetryWorkerService(options =>
        {
            options.ConnectionString = configuration["ApplicationInsights:ConnectionString"];
        });
        services.ConfigureFunctionsApplicationInsights();

        // --- Options ---
        services.Configure<AppOptions>(configuration.GetSection("App"));
        services.Configure<CosmosDbOptions>(configuration.GetSection("CosmosDb"));

        // --- Repository ---
        services.AddSingleton<IItemRepository, CosmosItemRepository>();

        // --- Services ---
        services.AddScoped<IMyService, MyService>();
        services.AddScoped<IMessageProcessor, MessageProcessor>();
        services.AddScoped<ICleanupService, CleanupService>();

        // --- Polly resilience ---
        services.AddHttpClient<IExternalApiClient, ExternalApiClient>()
            .AddPolicyHandler(ResiliencePolicies.GetRetryPolicy())
            .AddPolicyHandler(ResiliencePolicies.GetCircuitBreakerPolicy());

        // --- Health checks ---
        services.AddHealthChecks()
            .AddCosmosDb(sp => sp.GetRequiredService<CosmosClient>(),
                name: "cosmosdb", tags: new[] { "db" });
    })
    .UseSerilog()
    .Build();

await host.RunAsync();
```

---

## Repository Cosmos DB

```csharp
// src/MyFunction/Data/CosmosItemRepository.cs
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Options;
using Serilog;

namespace MyFunction.Data;

/// <summary>
/// Repository Cosmos DB con pattern ottimistici e query parametrizzate.
/// </summary>
public sealed class CosmosItemRepository : IItemRepository
{
    private readonly Container _container;
    private readonly ILogger<CosmosItemRepository> _logger;

    public CosmosItemRepository(
        CosmosClient client,
        IOptions<CosmosDbOptions> options,
        ILogger<CosmosItemRepository> logger)
    {
        _container = client
            .GetDatabase(options.Value.DatabaseName)
            .GetContainer(options.Value.ContainerName);
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<ItemDocument?> GetByIdAsync(string id, string partitionKey, CancellationToken ct = default)
    {
        _logger.LogInformation("Fetching item {Id}", id);

        try
        {
            var response = await _container.ReadItemAsync<ItemDocument>(id, new PartitionKey(partitionKey), cancellationToken: ct);
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ItemDocument>> QueryByOwnerAsync(string ownerId, CancellationToken ct = default)
    {
        _logger.LogInformation("Querying items for owner {OwnerId}", ownerId);

        // Query parametrizzata — mai string interpolation con dati utente
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE c.ownerId = @ownerId AND c.deleted = false ORDER BY c._ts DESC")
            .WithParameter("@ownerId", ownerId);

        var results = new List<ItemDocument>();
        using var feed = _container.GetItemQueryIterator<ItemDocument>(query);

        while (feed.HasMoreResults)
        {
            var page = await feed.ReadNextAsync(ct);
            _logger.LogDebug("Page fetched. RequestCharge={RU}", page.RequestCharge);
            results.AddRange(page);
        }

        return results.AsReadOnly();
    }

    /// <inheritdoc />
    public async Task<ItemDocument> UpsertAsync(ItemDocument item, CancellationToken ct = default)
    {
        _logger.LogInformation("Upserting item {Id}", item.Id);

        var response = await _container.UpsertItemAsync(
            item,
            new PartitionKey(item.OwnerId),
            new ItemRequestOptions { IfMatchEtag = item.ETag }, // ottimistic concurrency
            ct);

        return response.Resource;
    }

    /// <inheritdoc />
    public async Task DeleteAsync(string id, string partitionKey, CancellationToken ct = default)
    {
        _logger.LogInformation("Soft-deleting item {Id}", id);

        // Soft delete con patch
        var patchOps = new List<PatchOperation>
        {
            PatchOperation.Set("/deleted", true),
            PatchOperation.Set("/deletedAt", DateTime.UtcNow)
        };

        await _container.PatchItemAsync<ItemDocument>(
            id, new PartitionKey(partitionKey), patchOps, cancellationToken: ct);
    }
}
```

---

## Service Bus — Pattern di riferimento

```csharp
// src/MyFunction/Infrastructure/ServiceBusSender.cs
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace MyFunction.Infrastructure;

/// <summary>
/// Wrapper Service Bus con safe batching e error handling.
/// </summary>
public sealed class ServiceBusMessageSender : IServiceBusMessageSender, IAsyncDisposable
{
    private readonly ServiceBusSender _sender;
    private readonly ILogger<ServiceBusMessageSender> _logger;

    public ServiceBusMessageSender(
        ServiceBusClient client,
        string queueName,
        ILogger<ServiceBusMessageSender> logger)
    {
        _sender = client.CreateSender(queueName);
        _logger = logger;
    }

    /// <summary>
    /// Invia messaggi in batch con safe batching.
    /// </summary>
    public async Task SendBatchAsync<T>(
        IEnumerable<T> items,
        CancellationToken ct = default)
    {
        using var batch = await _sender.CreateMessageBatchAsync(ct);

        foreach (var item in items)
        {
            var message = new ServiceBusMessage(JsonSerializer.SerializeToUtf8Bytes(item))
            {
                ContentType = "application/json",
                MessageId = Guid.NewGuid().ToString(),
                CorrelationId = Activity.Current?.TraceId.ToString()
            };

            if (!batch.TryAddMessage(message))
            {
                _logger.LogWarning("Message too large for batch, sending individually");
                await _sender.SendMessageAsync(message, ct);
            }
        }

        if (batch.Count > 0)
        {
            _logger.LogInformation("Sending batch of {Count} messages", batch.Count);
            await _sender.SendMessagesAsync(batch, ct);
        }
    }

    public async ValueTask DisposeAsync() => await _sender.DisposeAsync();
}
```

---

## Bicep Infrastructure as Code

### main.bicep — Stack completo

```bicep
// infra/main.bicep
targetScope = 'resourceGroup'

@description('Environment name: dev, staging, prod')
param environment string = 'dev'

@description('Azure region')
param location string = resourceGroup().location

@description('Project name (used in resource names)')
param projectName string = 'myservice'

var tags = {
  Environment: environment
  Project: projectName
  ManagedBy: 'Bicep'
}

// --- Managed Identity ---
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-mi-${environment}'
  location: location
  tags: tags
}

// --- Key Vault ---
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${projectName}-${environment}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: environment == 'prod'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// RBAC: Managed Identity → Key Vault Secrets User
resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// --- Cosmos DB ---
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-02-15-preview' = {
  name: 'cosmos-${projectName}-${environment}'
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: environment == 'prod'
    enableMultipleWriteLocations: false
    backupPolicy: {
      type: environment == 'prod' ? 'Continuous' : 'Periodic'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-02-15-preview' = {
  parent: cosmosAccount
  name: '${projectName}db'
  properties: {
    resource: { id: '${projectName}db' }
    options: { throughput: 400 }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-02-15-preview' = {
  parent: cosmosDatabase
  name: 'Items'
  properties: {
    resource: {
      id: 'Items'
      partitionKey: {
        paths: ['/ownerId']
        kind: 'Hash'
      }
      defaultTtl: -1
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
      }
    }
  }
}

// RBAC: Managed Identity → Cosmos DB Data Contributor
resource cosmosDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosAccount.id, managedIdentity.id, '00000000-0000-0000-0000-000000000002')
  scope: cosmosAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00000000-0000-0000-0000-000000000002')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// --- Service Bus ---
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: 'sb-${projectName}-${environment}'
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'Premium' : 'Standard'
    tier: environment == 'prod' ? 'Premium' : 'Standard'
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'my-queue'
  properties: {
    maxDeliveryCount: 5
    deadLetteringOnMessageExpiration: true
    lockDuration: 'PT5M'
    defaultMessageTimeToLive: 'P14D'
  }
}

// --- Storage Account ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: 'st${projectName}${environment}'
  location: location
  tags: tags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// --- Application Insights ---
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${projectName}-${environment}'
  location: location
  tags: tags
  properties: {
    retentionInDays: environment == 'prod' ? 90 : 30
    sku: { name: 'PerGB2018' }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${projectName}-${environment}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// --- App Service Plan ---
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'plan-${projectName}-${environment}'
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'EP1' : 'Y1'
    tier: environment == 'prod' ? 'ElasticPremium' : 'Dynamic'
  }
  kind: 'functionapp'
  properties: {
    reserved: true // Linux
  }
}

// --- Function App ---
resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'func-${projectName}-${environment}'
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'CosmosDb__Endpoint'
          value: cosmosAccount.properties.documentEndpoint
        }
        {
          name: 'ServiceBus__Namespace'
          value: '${serviceBusNamespace.name}.servicebus.windows.net'
        }
        {
          name: 'KeyVault__Url'
          value: keyVault.properties.vaultUri
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        }
      ]
    }
  }
}

// --- Outputs ---
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output keyVaultUrl string = keyVault.properties.vaultUri
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output managedIdentityClientId string = managedIdentity.properties.clientId
```

---

## Dockerfile multi-stage Azure Functions

```dockerfile
# Dockerfile (Azure Functions Isolated Worker)
FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0 AS base
WORKDIR /home/site/wwwroot
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/MyFunction/MyFunction.csproj", "MyFunction/"]
RUN dotnet restore "MyFunction/MyFunction.csproj"

COPY src/MyFunction/ MyFunction/
WORKDIR /src/MyFunction
RUN dotnet publish -c Release -o /app/publish \
    --no-restore \
    -p:PublishReadyToRun=true

FROM base AS final
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
COPY --from=build /app/publish /home/site/wwwroot
```

---

## docker-compose.yml con Azurite

```yaml
# docker-compose.yml
version: "3.8"

services:
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite:latest
    ports:
      - "10000:10000"  # Blob
      - "10001:10001"  # Queue
      - "10002:10002"  # Table
    volumes:
      - azurite_data:/data
    command: "azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0"

  cosmosdb-emulator:
    image: mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:latest
    ports:
      - "8081:8081"
      - "10251-10254:10251-10254"
    environment:
      - AZURE_COSMOS_EMULATOR_PARTITION_COUNT=3
      - AZURE_COSMOS_EMULATOR_ENABLE_DATA_PERSISTENCE=true
    volumes:
      - cosmos_data:/tmp/cosmos/appdata

  function:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "7071:80"
    depends_on:
      - azurite
      - cosmosdb-emulator
    environment:
      - AzureWebJobsStorage=UseDevelopmentStorage=true
      - AzureWebJobsStorage__blobServiceUri=http://azurite:10000/devstoreaccount1
      - CosmosDb__Endpoint=https://cosmosdb-emulator:8081
      - CosmosDb__Key=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==
      - FUNCTIONS_WORKER_RUNTIME=dotnet-isolated

volumes:
  azurite_data:
  cosmos_data:
```

---

## appsettings.json

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "FUNCTIONS_EXTENSION_VERSION": "~4"
  },
  "App": {
    "ServiceName": "my-function",
    "Environment": "Development"
  },
  "CosmosDb": {
    "Endpoint": "https://localhost:8081",
    "DatabaseName": "myservicedb",
    "ContainerName": "Items"
  },
  "ServiceBus": {
    "Namespace": "sb-myservice-dev.servicebus.windows.net"
  },
  "KeyVault": {
    "Url": "https://kv-myservice-dev.vault.azure.net/"
  },
  "ApplicationInsights": {
    "ConnectionString": ""
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning",
        "Azure": "Warning"
      }
    }
  }
}
```

---

## CI/CD — GitHub Actions

```yaml
# .github/workflows/deploy-azure.yml
name: Deploy to Azure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AZURE_FUNCTIONAPP_PACKAGE_PATH: src/MyFunction
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

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore -c Release

      - name: Test
        run: dotnet test --no-build -c Release --verbosity normal

      - name: Security scan (no hardcoded secrets)
        run: |
          if grep -rn "AccountKey=\|DefaultEndpointsProtocol=https;AccountName=" \
            --include="*.cs" --include="*.json" \
            --exclude="*local.settings.json" \
            --exclude-dir=".git" .; then
            echo "BLOCKER: Hardcoded Azure connection strings found"
            exit 1
          fi

  deploy-infra:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Bicep
        uses: azure/arm-deploy@v2
        with:
          resourceGroupName: ${{ secrets.AZURE_RG }}
          template: infra/main.bicep
          parameters: environment=prod

  deploy-code:
    needs: deploy-infra
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Build artifact
        run: dotnet publish ${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }} \
          -c Release -o ./artifact --no-restore

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Function App
        uses: Azure/functions-action@v1
        with:
          app-name: ${{ secrets.AZURE_FUNCTIONAPP_NAME }}
          package: ./artifact
          respect-funcignore: true
```

---

## Azure Best Practices

### 1. Costi

```markdown
**Principi**:
- Azure Functions Consumption Plan → pay-per-execution, $0 quando idle
- Cosmos DB: autoscale throughput (RU/s) invece di provisioned fisso
- Log Analytics: retention 30gg dev, 90gg prod (non infinita)
- Storage lifecycle: blob cool tier dopo 30gg, archive dopo 90gg

**Stima costi mensili (baseline)**:
- Function App (Consumption): 1M esecuzioni, 512MB, 500ms → ~$0.80/mese
- Cosmos DB (serverless): 1M read + 500K write → ~$0.25/mese
- Service Bus (Standard): 1M messaggi → ~$0.10/mese
- Application Insights: 5GB/mese → incluso nel free tier

**Tag obbligatori su tutte le risorse**:
  Environment: dev | staging | prod
  Project: <nome>
  ManagedBy: Bicep | Terraform

**Alerting costi**:
- Budget alert al 80% e 100% del budget mensile
- Azure Cost Management: export giornaliero verso Storage
```

### 2. Performance

```markdown
**Function App**:
- Premium Plan (EP1) in prod per eliminare cold start
- FUNCTIONS_WORKER_PROCESS_COUNT = n CPU cores per concorrenza
- Connection pooling: CosmosClient singleton (non scoped)
- HttpClient via IHttpClientFactory (non new HttpClient())

**Cosmos DB**:
- Partition key ad alta cardinalità (mai booleani o enum)
- Query con filtro su partition key (cross-partition scan = costoso)
- Indicizzazione custom: escludi path non usati in query
- Preferred locations: region più vicina all'utente

**Service Bus**:
- MaxConcurrentCalls = numero core × 2
- PrefetchCount = MaxConcurrentCalls × 20
- Session-based per ordering garantito

**Application Insights Sampling**:
- Adaptive sampling abilitato in prod (riduce volume telemetria)
- Fixed rate 100% in dev/staging
```

### 3. Affidabilità

```markdown
**Function App**:
- Retry policy configurata in host.json (3 tentativi, backoff exp)
- Health check endpoint + Application Insights availability test
- Deployment slots (staging → prod) con swap senza downtime

**Cosmos DB**:
- Session consistency (default): bilanciamento latenza/consistenza
- Multi-region read (geo-replication) in prod
- Backup continuo (Continuous backup) in prod

**Service Bus**:
- Dead-letter queue monitorata con alert su count > 0
- maxDeliveryCount = 5 (dopo → DLQ automatico)
- Lock duration > timeout elaborazione previsto

**Resilienza con Polly**:
- Retry con exponential backoff + jitter
- Circuit breaker per chiamate HTTP esterne
- Timeout policy su tutte le operazioni I/O

host.json:
{
  "version": "2.0",
  "retry": {
    "strategy": "exponentialBackoff",
    "maxRetryCount": 3,
    "minimumInterval": "00:00:02",
    "maximumInterval": "00:02:00"
  }
}
```

### 4. Sicurezza

```markdown
**Identità**:
- Managed Identity (user-assigned) per tutti i servizi — mai connection strings
- DefaultAzureCredential in sviluppo; ManagedIdentityCredential in produzione
- RBAC least privilege: assegna solo il ruolo necessario (es. Cosmos DB Data Reader, non Contributor)

**Key Vault**:
- Tutti i segreti in Key Vault (no appsettings.json in prod)
- Secret rotation automatica con Function trigger
- Soft delete + purge protection in prod
- Audit log abilitato

**Network**:
- HTTPS only + TLS 1.2 minimo
- Private endpoints per Cosmos DB e Service Bus in prod
- Function App con VNet integration
- WAF (Azure Front Door o Application Gateway) davanti all'API

**Checklist sicurezza**:
- [ ] Nessuna connection string hardcoded
- [ ] Nessun secret in appsettings.json (usa Key Vault references)
- [ ] Managed Identity abilitata
- [ ] RBAC configurato (no Contributor/Owner su identità app)
- [ ] HTTPS only abilitato
- [ ] Blob public access disabilitato
- [ ] Diagnostic settings abilitati (audit log → Log Analytics)
- [ ] Defender for Cloud abilitato (almeno Free tier)
```

---

## Script CLI — AZURE-SETUP.md

```bash
#!/bin/bash
# azure-setup.sh — provisioning manuale per sviluppo locale

RESOURCE_GROUP="rg-myservice-dev"
LOCATION="westeurope"
PROJECT="myservice"
ENV="dev"

# Login
az login
az account set --subscription "<subscription-id>"

# Resource Group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Environment=$ENV Project=$PROJECT ManagedBy=CLI

# Managed Identity
az identity create \
  --name "${PROJECT}-mi-${ENV}" \
  --resource-group $RESOURCE_GROUP

MI_PRINCIPAL_ID=$(az identity show \
  --name "${PROJECT}-mi-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

# Key Vault
az keyvault create \
  --name "kv-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --enable-rbac-authorization true

# RBAC: Managed Identity → Key Vault Secrets User
az role assignment create \
  --assignee $MI_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope $(az keyvault show --name "kv-${PROJECT}-${ENV}" --resource-group $RESOURCE_GROUP --query id -o tsv)

# Cosmos DB
az cosmosdb create \
  --name "cosmos-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --locations regionName=$LOCATION \
  --default-consistency-level Session \
  --enable-automatic-failover false

az cosmosdb sql database create \
  --account-name "cosmos-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --name "${PROJECT}db"

az cosmosdb sql container create \
  --account-name "cosmos-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --database-name "${PROJECT}db" \
  --name "Items" \
  --partition-key-path "/ownerId"

# RBAC: Managed Identity → Cosmos DB Data Contributor
COSMOS_ID=$(az cosmosdb show \
  --name "cosmos-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

az role assignment create \
  --assignee $MI_PRINCIPAL_ID \
  --role "Cosmos DB Built-in Data Contributor" \
  --scope $COSMOS_ID

# Service Bus
az servicebus namespace create \
  --name "sb-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard

az servicebus queue create \
  --name "my-queue" \
  --namespace-name "sb-${PROJECT}-${ENV}" \
  --resource-group $RESOURCE_GROUP \
  --max-delivery-count 5 \
  --dead-lettering-on-message-expiration true

echo "Setup complete."
echo "Cosmos endpoint: $(az cosmosdb show --name cosmos-${PROJECT}-${ENV} --resource-group $RESOURCE_GROUP --query documentEndpoint -o tsv)"
echo "Key Vault URL: $(az keyvault show --name kv-${PROJECT}-${ENV} --resource-group $RESOURCE_GROUP --query properties.vaultUri -o tsv)"
```

---

## Riferimenti

- [Azure Functions Isolated Worker](https://learn.microsoft.com/azure/azure-functions/dotnet-isolated-process-guide)
- [DefaultAzureCredential](https://learn.microsoft.com/dotnet/azure/sdk/authentication/credential-chains)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Cosmos DB .NET SDK v3](https://learn.microsoft.com/azure/cosmos-db/nosql/sdk-dotnet-v3)
- [Azure Service Bus .NET SDK](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Azurite Emulator](https://learn.microsoft.com/azure/storage/common/storage-use-azurite)
