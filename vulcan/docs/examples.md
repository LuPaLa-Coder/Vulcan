# Vulcan Examples

## Real-World Scenarios

### Example 1: Create REST API for E-Commerce (Azure)

**Scenario**: Building a product management API for e-commerce platform on Azure

**Requirements**:
- Azure Functions (HTTP triggers)
- Cosmos DB for product data
- Bearer token authentication
- Input validation
- Structured logging
- Pagination support

**Request to Vulcan**:
```
Crea un'API REST per la gestione prodotti con:
- Azure Functions (HTTP trigger)
- Cosmos DB per persistenza
- Autenticazione bearer token (header Authorization)
- Validazione input con FluentValidation
- Logging strutturato con Serilog
- Paginazione (top, skip)
- Error handling con status codes appropriati
- DTOs separate dalle entity
```

**Vulcan generates**:

```csharp
// ProductController.cs
[FunctionName("GetProducts")]
public async Task<IActionResult> GetProducts(
    [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products")] 
    HttpRequest req,
    ILogger log)
{
    // Bearer token validation
    // Query paging (top, skip)
    // Logging
    // Cosmos DB fetch
    // Return paginated results
}

// ProductService.cs
public class ProductService
{
    private readonly IProductRepository _repository;
    private readonly ILogger<ProductService> _logger;
    
    public async Task<PagedResult<ProductDto>> GetProductsAsync(int top, int skip)
    {
        // Business logic: fetch, map, paginate
        // Logging at key points
        // Error handling
    }
}

// ProductRepository.cs
public class ProductRepository : IProductRepository
{
    private readonly CosmosClient _cosmosClient;
    
    public async Task<List<Product>> GetAsync(int top, int skip)
    {
        // Cosmos DB query with pagination
        // Proper error handling
    }
}

// Validators/ProductValidator.cs
public class CreateProductValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductValidator()
    {
        RuleFor(p => p.Name).NotEmpty().Length(1, 255);
        RuleFor(p => p.Price).GreaterThan(0);
        // More rules...
    }
}

// DependencyInjection.cs
public static IServiceCollection AddProductServices(this IServiceCollection services)
{
    services.AddScoped<IProductRepository, ProductRepository>();
    services.AddScoped<ProductService>();
    services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
    return services;
}

// main.bicep (Infrastructure as Code)
param location string = resourceGroup().location

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: 'cosmosdb-products'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    // More config...
  }
}

// Tests/ProductServiceTests.cs
[TestClass]
public class ProductServiceTests
{
    private Mock<IProductRepository> _repositoryMock;
    private ProductService _service;
    
    [TestInitialize]
    public void Setup()
    {
        _repositoryMock = new Mock<IProductRepository>();
        _service = new ProductService(_repositoryMock.Object, new TestLogger());
    }
    
    [TestMethod]
    public async Task GetProducts_ReturnsPagedResults()
    {
        // Arrange
        _repositoryMock.Setup(r => r.GetAsync(It.IsAny<int>(), It.IsAny<int>()))
            .ReturnsAsync(new List<Product> { /* test data */ });
        
        // Act
        var result = await _service.GetProductsAsync(10, 0);
        
        // Assert
        Assert.IsNotNull(result);
        Assert.AreEqual(1, result.Items.Count);
    }
}
```

**Integration**:
```bash
# Copy generated files
cp -r generated/Services ./YourProject/
cp -r generated/Controllers ./YourProject/
cp -r generated/Validators ./YourProject/
cp generated/DependencyInjection.cs ./YourProject/

# Deploy infrastructure
dotnet build
az deployment group create --resource-group myRg --template-file bicep/main.bicep

# Deploy function
func azure functionapp publish myFunctionApp
```

**Result**: Production-ready API deployed on Azure.

---

### Example 2: Create Lambda Function for Data Processing (AWS)

**Scenario**: Process CSV files uploaded to S3, validate data, store in DynamoDB

**Requirements**:
- Lambda function triggered by S3 upload
- CSV parsing
- Data validation
- DynamoDB storage
- CloudWatch logging
- Error handling & retry logic

**Request to Vulcan**:
```
Crea una Lambda function per:
- Trigger S3 upload (object created)
- Parse CSV file
- Validazione dati con regole custom
- Salva su DynamoDB
- Logging con CloudWatch
- Error handling e retry policy
```

**Vulcan generates**:

```csharp
// ProcessCsvFunction.cs (Lambda handler)
public class ProcessCsvFunction
{
    private readonly IS3Service _s3Service;
    private readonly ICsvProcessor _csvProcessor;
    private readonly IDynamoDbRepository _repository;
    private readonly ILogger<ProcessCsvFunction> _logger;
    
    [LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
    public async Task<APIGatewayProxyResponse> FunctionHandler(S3Event s3Event)
    {
        foreach (var record in s3Event.Records)
        {
            try
            {
                // Get CSV from S3
                var csv = await _s3Service.GetObjectAsync(record.S3.Bucket.Name, record.S3.Object.Key);
                
                // Process CSV
                var rows = _csvProcessor.Parse(csv);
                
                // Validate each row
                var validRows = rows.Where(r => _csvProcessor.Validate(r)).ToList();
                
                // Store in DynamoDB
                foreach (var row in validRows)
                {
                    await _repository.SaveAsync(MapToDomainModel(row));
                }
                
                _logger.LogInformation($"Processed {validRows.Count} records");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing CSV");
                // Publish to SQS for retry
                await _sqsService.SendAsync(new RetryMessage { ... });
            }
        }
    }
}

// CsvProcessor.cs
public class CsvProcessor : ICsvProcessor
{
    private readonly IValidator<CsvRow> _validator;
    
    public List<CsvRow> Parse(string csvContent)
    {
        using var reader = new StringReader(csvContent);
        using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
        return csv.GetRecords<CsvRow>().ToList();
    }
    
    public bool Validate(CsvRow row)
    {
        var result = _validator.Validate(row);
        return result.IsValid;
    }
}

// DynamoDbRepository.cs
public class DynamoDbRepository : IDynamoDbRepository
{
    private readonly IAmazonDynamoDB _dynamoDbClient;
    
    public async Task SaveAsync(DataRecord record)
    {
        var request = new PutItemRequest
        {
            TableName = "DataRecords",
            Item = new Dictionary<string, AttributeValue>
            {
                { "Id", new AttributeValue { S = record.Id } },
                { "Data", new AttributeValue { S = JsonConvert.SerializeObject(record) } },
                { "Timestamp", new AttributeValue { N = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString() } }
            }
        };
        
        await _dynamoDbClient.PutItemAsync(request);
    }
}

// Startup.cs (Lambda custom runtime with DI)
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddAWSLambdaHosting<LambdaEntryPoint>();
        services.AddScoped<IS3Service, S3Service>();
        services.AddScoped<ICsvProcessor, CsvProcessor>();
        services.AddScoped<IDynamoDbRepository, DynamoDbRepository>();
        services.AddSingleton(new AmazonS3Client());
        services.AddSingleton(new AmazonDynamoDBClient());
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
    }
}

// cdk/CsvProcessorStack.cs (Infrastructure as Code)
public class CsvProcessorStack : Stack
{
    public CsvProcessorStack(Construct scope, string id, IStackProps props = null) : base(scope, id, props)
    {
        // S3 bucket
        var csvBucket = new Bucket(this, "CsvBucket");
        
        // DynamoDB table
        var dataTable = new Table(this, "DataRecords", new TableProps
        {
            PartitionKey = new Attribute { Name = "Id", Type = AttributeType.STRING },
            BillingMode = BillingMode.PAY_PER_REQUEST
        });
        
        // Lambda function
        var lambdaRole = new Role(this, "LambdaRole", new RoleProps
        {
            AssumedBy = new ServicePrincipal("lambda.amazonaws.com")
        });
        
        csvBucket.GrantRead(lambdaRole);
        dataTable.GrantWriteData(lambdaRole);
        
        var function = new Function(this, "ProcessCsvFunction", new FunctionProps
        {
            Runtime = Runtime.DOTNET_8,
            Code = Code.FromAsset("src/lambda"),
            Handler = "ProcessCsvFunction::ProcessCsvFunction::FunctionHandler",
            Role = lambdaRole,
            Environment = new Dictionary<string, string>
            {
                { "DYNAMODB_TABLE", dataTable.TableName }
            }
        });
        
        // S3 trigger
        function.AddEventSource(new S3EventSource(csvBucket, new S3EventSourceProps
        {
            Events = new[] { EventType.OBJECT_CREATED }
        }));
    }
}

// Tests/ProcessCsvFunctionTests.cs
[TestClass]
public class ProcessCsvFunctionTests
{
    private Mock<IS3Service> _s3ServiceMock;
    private Mock<ICsvProcessor> _csvProcessorMock;
    private Mock<IDynamoDbRepository> _repositoryMock;
    private ProcessCsvFunction _function;
    
    [TestInitialize]
    public void Setup()
    {
        _s3ServiceMock = new Mock<IS3Service>();
        _csvProcessorMock = new Mock<ICsvProcessor>();
        _repositoryMock = new Mock<IDynamoDbRepository>();
        _function = new ProcessCsvFunction(
            _s3ServiceMock.Object,
            _csvProcessorMock.Object,
            _repositoryMock.Object,
            new TestLogger()
        );
    }
    
    [TestMethod]
    public async Task FunctionHandler_ProcessesValidRows()
    {
        // Arrange
        var s3Event = new S3Event { /* event data */ };
        var csvContent = "Name,Email\nJohn,john@example.com\n";
        
        _s3ServiceMock
            .Setup(s => s.GetObjectAsync(It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(csvContent);
        
        var rows = new List<CsvRow> { new CsvRow { Name = "John", Email = "john@example.com" } };
        _csvProcessorMock.Setup(c => c.Parse(csvContent)).Returns(rows);
        _csvProcessorMock.Setup(c => c.Validate(It.IsAny<CsvRow>())).Returns(true);
        
        // Act
        var result = await _function.FunctionHandler(s3Event);
        
        // Assert
        Assert.IsNotNull(result);
        _repositoryMock.Verify(r => r.SaveAsync(It.IsAny<DataRecord>()), Times.Once);
    }
}
```

**Deployment**:
```bash
# Deploy with CDK
cdk deploy

# Or with SAM
sam build
sam deploy --guided

# Monitor in CloudWatch
aws logs tail /aws/lambda/ProcessCsvFunction --follow
```

**Result**: Serverless CSV processing on AWS Lambda.

---

### Example 3: Refactor Legacy Code to Clean Architecture

**Scenario**: Legacy `UserManager` class needs modernization

**Before** (spaghetti code):
```csharp
public class UserManager
{
    private SqlConnection _conn = new SqlConnection("server=...");
    
    public void CreateUser(string name, string email, string password)
    {
        try
        {
            _conn.Open();
            // SQL injection vulnerability!
            string sql = $"INSERT INTO Users VALUES ('{name}', '{email}', '{password}')";
            var cmd = new SqlCommand(sql, _conn);
            cmd.ExecuteNonQuery();
        }
        catch (Exception ex)
        {
            // Silent failure
            Console.WriteLine(ex.Message);
        }
        finally
        {
            _conn.Close();
        }
    }
}
```

**Request to Vulcan**:
```
Refactor questa classe UserManager in architettura pulita:
- Repository pattern per data access
- Service layer per business logic
- DTO separate dalle entity
- Validazione con FluentValidation
- Proper error handling
- Structured logging
- Dependency injection
- Unit testable

[paste legacy code]
```

**Vulcan generates**:

```csharp
// IUserRepository.cs
public interface IUserRepository
{
    Task<User> CreateAsync(User user);
    Task<User> GetByIdAsync(int id);
    Task UpdateAsync(User user);
    Task DeleteAsync(int id);
}

// UserRepository.cs
public class UserRepository : IUserRepository
{
    private readonly IApplicationDbContext _dbContext;
    
    public async Task<User> CreateAsync(User user)
    {
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync();
        return user;
    }
}

// UserService.cs
public class UserService
{
    private readonly IUserRepository _repository;
    private readonly IValidator<CreateUserDto> _validator;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ILogger<UserService> _logger;
    
    public async Task<UserDto> CreateUserAsync(CreateUserDto dto)
    {
        // Validate input
        var validationResult = await _validator.ValidateAsync(dto);
        if (!validationResult.IsValid)
            throw new ValidationException(validationResult.Errors);
        
        // Hash password
        var hashedPassword = _passwordHasher.Hash(dto.Password);
        
        // Create domain model
        var user = new User
        {
            Name = dto.Name,
            Email = dto.Email,
            PasswordHash = hashedPassword
        };
        
        // Persist
        var created = await _repository.CreateAsync(user);
        _logger.LogInformation("User created: {UserId}", created.Id);
        
        // Return DTO
        return MapToDto(created);
    }
}

// CreateUserValidator.cs
public class CreateUserValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserValidator()
    {
        RuleFor(u => u.Name)
            .NotEmpty()
            .Length(2, 100);
        
        RuleFor(u => u.Email)
            .NotEmpty()
            .EmailAddress();
        
        RuleFor(u => u.Password)
            .NotEmpty()
            .MinimumLength(8)
            .Matches(@"[A-Z]", "must contain uppercase")
            .Matches(@"[0-9]", "must contain digit");
    }
}

// DTOs
public class CreateUserDto
{
    public string Name { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
}

public class UserDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
}

// Tests
[TestClass]
public class UserServiceTests
{
    [TestMethod]
    public async Task CreateUserAsync_WithValidData_CreatesUser()
    {
        // Arrange
        var repositoryMock = new Mock<IUserRepository>();
        var validatorMock = new Mock<IValidator<CreateUserDto>>();
        var passwordHasherMock = new Mock<IPasswordHasher>();
        
        var service = new UserService(repositoryMock.Object, validatorMock.Object, passwordHasherMock.Object, new TestLogger());
        
        var dto = new CreateUserDto { Name = "John", Email = "john@example.com", Password = "SecurePass1" };
        
        // Act
        var result = await service.CreateUserAsync(dto);
        
        // Assert
        Assert.IsNotNull(result);
        repositoryMock.Verify(r => r.CreateAsync(It.IsAny<User>()), Times.Once);
    }
}
```

**Integration**:
```bash
# Review the generated code
diff UserManager.cs generated/UserService.cs

# Copy new implementation
cp generated/UserService.cs ./Services/
cp generated/UserRepository.cs ./Data/Repositories/
cp generated/Validators/ ./Validators/

# Update DI container
services.AddScoped<IUserRepository, UserRepository>();
services.AddScoped<UserService>();

# Run tests to ensure compatibility
dotnet test

# Commit refactoring
git add .
git commit -m "Refactor UserManager to clean architecture with Repository pattern"
```

**Result**: Modern, testable, secure user management.

---

## Quick Reference

### Command Cheatsheet

```bash
# Generate API
copilot /agent Vulcan
"Create REST API for..."

# Generate Lambda function
"Create Lambda function for..."

# Generate Azure Function
"Create Azure Function for..."

# Refactor existing code
"Refactor this code to clean architecture..."

# Generate microservice
"Create microservice with API and worker..."
```

### Cloud Indicator Keywords

**AWS**: Lambda, DynamoDB, S3, SQS, SNS, ECS, Fargate, API Gateway, CloudWatch, CDK, SAM
**Azure**: Functions, Cosmos DB, Service Bus, Container Apps, Application Insights, Bicep, Key Vault
**Generic**: No cloud-specific services

---

## Next Steps

- **Learn more**: See [Usage Guide](./usage.md)
- **Troubleshoot**: Check [Installation Guide](./installation.md)
- **Get help**: Review main [README](./README.md)

Happy coding! 🚀
