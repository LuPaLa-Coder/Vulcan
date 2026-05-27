# Vulcan Installation Guide

## Prerequisites

Before installing Vulcan, ensure you have:

### Required
- **Copilot CLI** (version 1.0.34 or later)
  ```bash
  copilot --version
  ```
- **GitHub account** with Copilot subscription
- **.NET SDK 8.0+**
  ```bash
  dotnet --version
  ```
- **Git** (for cloning)

### Recommended
- **PowerShell 7.0+** (Windows) or **Bash** (Linux/macOS)
- **Docker** (for containerized testing)
- **AWS CLI** (if using AWS target)
- **Azure CLI** (if using Azure target)

### Optional
- **Postman** or **curl** (for API testing)
- **SQL Server Management Studio** or **Azure Data Studio** (if using SQL Server)
- **MongoDB Compass** (if using MongoDB)

## Installation Methods

### Option 1: Clone Repository (Recommended)

Clone the Vulcan repository directly:

```bash
git clone https://github.com/PaoEng/Vulcan.git
cd Vulcan
```

### Option 2: Install as Copilot CLI Agent (Fastest)

Copy the agent file to your Copilot CLI agents directory:

```bash
# Linux/macOS
cp Vulcan.agent.md ~/.copilot/agents/

# Windows
copy Vulcan.agent.md %USERPROFILE%\.copilot\agents\
```

Then in Copilot CLI:
```
copilot /agent
# Select "Vulcan"
```

### Option 3: Download ZIP

Download the repository as ZIP from GitHub and extract:

```bash
# Extract and navigate
unzip Vulcan-main.zip
cd Vulcan-main
```

## Verification

Verify the installation:

```bash
# Check agent file exists
ls -la Vulcan.agent.md

# Check docs folder
ls -la docs/

# Verify .NET SDK
dotnet --version
```

Expected structure:
```
Vulcan/
├── Vulcan.agent.md
├── README.md
└── docs/
    ├── installation.md  (this file)
    ├── usage.md
    └── examples.md
```

## Configuration

### Environment Variables (Optional)

```bash
# AWS Configuration (if using AWS target)
export AWS_PROFILE=your-profile
export AWS_REGION=us-east-1

# Azure Configuration (if using Azure target)
export AZURE_SUBSCRIPTION_ID=your-subscription-id
export AZURE_TENANT_ID=your-tenant-id

# Vulcan Preferences (optional)
export VULCAN_DEFAULT_CLOUD=aws  # aws, azure, or generic
export VULCAN_FRAMEWORK=net8  # net8 (default) or net9
```

### Agent Registration (Copilot CLI)

If using Copilot CLI (Option 2), the agent should auto-register. To manually verify:

```
copilot /agent
# You should see "Vulcan" in the list
```

If the agent doesn't appear, ensure `Vulcan.agent.md` is in the correct location and restart Copilot CLI.

## Cloud Setup (Optional)

### AWS Setup (for Lambda/ECS targets)

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure

# Install CDK (for Infrastructure as Code)
npm install -g aws-cdk
cdk --version
```

### Azure Setup (for Functions/Container Apps targets)

```bash
# Install Azure CLI
curl https://aka.ms/InstallAzureCLIDeb | bash

# Login to Azure
az login

# Install Bicep (for Infrastructure as Code)
az bicep install
az bicep version
```

## Quick Test

Verify Vulcan works:

1. **Start Copilot CLI**
   ```bash
   copilot
   /agent
   # Select: Vulcan
   ```

2. **Request a simple API endpoint**
   ```
   Create a C# API endpoint for getting user data from Cosmos DB
   ```

3. **Review generated code**
   - Should see UserController.cs
   - UserService.cs with repository pattern
   - Dependency injection setup
   - Error handling and logging

4. **Test in your project**
   ```bash
   # Copy generated files to your project
   cp generated/*.cs ./YourProject/
   
   # Build and verify
   dotnet build
   ```

## Troubleshooting

### Issue: Agent not appearing in `/agent` list

**Solution:**
1. Ensure agent file is in correct location (`~/.copilot/agents/`)
2. Restart Copilot CLI: `copilot /restart`
3. Check agent file format (should start with `---` YAML header)

### Issue: "Cloud SDK not found" error

**Solution:**
- For AWS: Install AWS CLI (`aws configure`)
- For Azure: Install Azure CLI (`az login`)
- For Generic: No cloud setup needed

### Issue: "Target cloud ambiguous" message

**Solution:**
- Vulcan will ask a single clarifying question
- Answer: "AWS", "Azure", or "generic"
- Or set `VULCAN_DEFAULT_CLOUD` environment variable

### Issue: Generated code doesn't compile

**Solution:**
- Ensure you have .NET 8.0+ installed
- Run `dotnet restore` in generated project directory
- Check target framework in generated .csproj files
- Review [examples.md](./examples.md) for similar scenario

### Issue: Can't connect to cloud services

**Solution:**
- Verify credentials are configured (`aws configure`, `az login`)
- Check service permissions (IAM for AWS, RBAC for Azure)
- Ensure service exists in your subscription/account

## Support

If you encounter issues:

1. **Check logs**: Enable verbose mode in Copilot CLI
2. **Review examples**: See [examples.md](./examples.md) for common scenarios
3. **Verify setup**: Ensure all prerequisites are installed
4. **Check cloud config**: Verify AWS/Azure credentials if applicable

## Next Steps

- Read the **[Usage Guide](./usage.md)** for detailed workflows
- Review **[Examples](./examples.md)** for real-world scenarios
- Start building production-ready C# code!

---

**Repository**: https://github.com/PaoEng/Vulcan.git

**Questions?** See the main [README](../README.md).
