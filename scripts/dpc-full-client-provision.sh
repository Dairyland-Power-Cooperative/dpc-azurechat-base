#!/bin/bash
# Description: This script provisions a full client environment in Azure using Bicep templates.
# It requires the Azure CLI and Bicep CLI to be installed and configured.

set -e  # Exit immediately if any command fails

# Define color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display usage information
usage() {
  echo "Usage: ./dpc-full-client-provision.sh -c <client_id> [-f]"
  echo "  -c, --client-id      Client identifier (required)"
  echo "  -f, --force          Skip confirmation prompt"
  echo "  -h, --help           Display this help message"
}

# Parse command line arguments
CLIENT_ID=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client-id)
      CLIENT_ID="$2"
      shift 2
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

# Check if CLIENT_ID is provided
if [[ -z "$CLIENT_ID" ]]; then
  echo -e "${RED}Error: Client ID is required.${NC}"
  usage
  exit 1
fi

# Validate client directory and parameter file
CLIENT_PATH="./infra/dpc/clients/$CLIENT_ID"
BICEPPARAM_FILE="$CLIENT_PATH/dpc_main.bicepparam"

if [[ ! -d "$CLIENT_PATH" ]]; then
  echo -e "${RED}Error: Client directory not found: $CLIENT_PATH${NC}"
  exit 1
fi

if [[ ! -f "$BICEPPARAM_FILE" ]]; then
  echo -e "${RED}Error: Bicepparam file not found: $BICEPPARAM_FILE${NC}"
  exit 1
fi

# Default subscription ID
SUBSCRIPTION_ID=""

# Try to get subscription ID from config.json if it exists
CONFIG_PATH="./infra/dpc/config.json"
if [[ -f "$CONFIG_PATH" ]]; then
  SUBSCRIPTION_ID=$(jq -r '.subscriptionId' "$CONFIG_PATH")
fi

# Check if subscription ID is valid
if [[ -z "$SUBSCRIPTION_ID" || "$SUBSCRIPTION_ID" == "null" ]]; then
  echo -e "${RED}Error: SubscriptionId not found in $CONFIG_PATH.${NC}"
  exit 1
fi

if [[ "$SUBSCRIPTION_ID" == "000-0000-0000-000000000000" ]]; then
  echo -e "${RED}Error: SubscriptionId not set. Please provide a valid SubscriptionId in $CONFIG_PATH${NC}"
  exit 1
fi

# Set Azure context
echo -e "${CYAN}Setting Azure context to subscription: $SUBSCRIPTION_ID${NC}"
if ! az account set --subscription "$SUBSCRIPTION_ID"; then
  echo -e "${RED}Error: Failed to set Azure subscription context. Please check if you're logged in and have access to the subscription.${NC}"
  exit 1
fi

# Confirm deployment
if [[ "$FORCE" != true ]]; then
  read -p "Deploy client '$CLIENT_ID' to subscription '$SUBSCRIPTION_ID'? (y/n): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
  fi
fi

# Deploy using az deployment sub command (for subscription-level deployments)
echo -e "${CYAN}Deploying infrastructure for client: $CLIENT_ID${NC}"
DEPLOYMENT_NAME="$CLIENT_ID-deployment-$(date +%Y%m%d-%H%M%S)"
RESULT=$(az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location northcentralus \
  --template-file "./infra/dpc/dpc_main.bicep" \
  --parameters "@$BICEPPARAM_FILE" \
  --query "properties.outputs" -o json)

# Check if deployment was successful
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Error: Deployment failed. Check Azure CLI output for details.${NC}"
  exit 1
fi

# Parse outputs to capture important values
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}Warning: jq command not found. Unable to parse deployment outputs automatically.${NC}"
  echo -e "${YELLOW}Please check the Azure portal for deployment results.${NC}"
else
  WEBAPP_NAME=$(echo $RESULT | jq -r '.AZURE_WEBAPP_NAME.value')
  RESOURCE_GROUP=$(echo $RESULT | jq -r '.AZURE_RESOURCE_GROUP.value')
  
  echo -e "${GREEN}Infrastructure deployment complete.${NC}"
  echo -e "${GREEN}Resource Group: $RESOURCE_GROUP${NC}"
  echo -e "${GREEN}Web App Name: $WEBAPP_NAME${NC}"

  # Create app registration
  echo -e "${CYAN}Creating app registration for web app: $WEBAPP_NAME${NC}"
  if [[ -f "./scripts/appreg_setup.sh" ]]; then
    #chmod +x ./scripts/appreg_setup.sh
    ./scripts/appreg_setup.sh -webappname "$WEBAPP_NAME"
  else
    echo -e "${YELLOW}Warning: App registration script (./scripts/appreg_setup.sh) not found.${NC}"
    echo -e "${YELLOW}Please create the app registration manually or ensure the script exists.${NC}"
  fi
fi

echo -e "${GREEN}Provisioning completed successfully for client: $CLIENT_ID${NC}"
exit 0