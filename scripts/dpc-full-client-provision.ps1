# Description: This script provisions a full client environment in Azure using Bicep templates.
# It requires the Azure CLI and Bicep CLI to be installed and configured.

param (
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$SubscriptionId = "000-0000-0000-000000000000" # Default value for SubscriptionId

# Validate client directory and parameter file
$clientPath = "./infra/dpc/clients/$ClientId"
$bicepParamFile = "$clientPath/dpc_main.bicepparam"

if (-not (Test-Path $clientPath)) {
    Write-Error "Client directory not found: $clientPath"
    exit 1
}

if (-not (Test-Path $bicepParamFile)) {
    Write-Error "Bicepparam file not found: $bicepParamFile"
    exit 1
}

# Try to get from config.json if it exists
$configPath = "./infra/dpc/config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    $SubscriptionId = $config.subscriptionId
}

if (-not $SubscriptionId) {
    Write-Error "SubscriptionId not found in /infra/dpc/config.json."
}
# Check if subscriptionId is still default value
if ($SubscriptionId -eq "000-0000-0000-000000000000") {
    Write-Error "SubscriptionId not set. Please provide a valid SubscriptionId in /infra/dpc/config.json"
    exit 1
}

# Set Azure context
Write-Host "Setting Azure context to subscription: $SubscriptionId" -ForegroundColor Cyan
az account set --subscription $SubscriptionId

# Confirm deployment
if (-not $Force) {
    $confirm = Read-Host "Deploy client '$ClientId' to subscription '$SubscriptionId'? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Deploy using az deployment sub command (for subscription-level deployments)
Write-Host "Deploying infrastructure for client: $ClientId" -ForegroundColor Cyan
$deploymentName = "$ClientId-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$result = az deployment sub create `
    --name $deploymentName `
    --location northcentralus `
    --template-file "./infra/dpc/dpc_main.bicep" `
    --parameters "@$bicepParamFile" `
    --query "properties.outputs" -o json

# Parse outputs to capture important values
$outputs = $result | ConvertFrom-Json
$webappName = $outputs.AZURE_WEBAPP_NAME.value
$resourceGroup = $outputs.AZURE_RESOURCE_GROUP.value

Write-Host "Infrastructure deployment complete." -ForegroundColor Green
Write-Host "Resource Group: $resourceGroup" -ForegroundColor Green
Write-Host "Web App Name: $webappName" -ForegroundColor Green

# Create app registration
Write-Host "Creating app registration for web app: $webappName" -ForegroundColor Cyan
./scripts/appreg_setup.ps1 -webappname $webappName

Write-Host "Provisioning completed successfully for client: $ClientId" -ForegroundColor Green