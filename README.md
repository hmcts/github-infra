# GitHub Infrastructure

This repository contains Terraform infrastructure as code (IaC) for managing GitHub-related Azure infrastructure for HMCTS. The infrastructure is deployed using Azure DevOps pipelines with support for multiple environments.

## 📋 Overview

This project provisions and manages:
- Azure Virtual Networks with subnet delegation for GitHub
- Network Security Groups (NSGs)
- Route Tables with custom routes
- VNet peering to HMCTS Hub networks
- GitHub Network Settings using Azure API

## 🏗️ Repository Structure

```
.
├── azure-pipelines.yaml          # Azure DevOps pipeline configuration
├── components/
│   └── network/                  # Network component module
│       ├── inputs-optional.tf    # Optional input variables
│       ├── inputs-required.tf    # Required input variables
│       ├── interpolated-defaults.tf  # Computed values
│       ├── network.tf            # Main network resources
│       ├── output.tf             # Output values
│       └── provider.tf           # Provider configuration
└── environments/
    ├── nonprod/                  # Non-production environment variables
    │   └── nonprod.tfvars
    ├── prod/                     # Production environment variables
    │   └── prod.tfvars
    └── sbox/                     # Sandbox environment variables
        └── sbox.tfvars
```

## 🚀 Components

### Network Component

The network component provisions:

- **Virtual Network**: Dedicated VNet for GitHub resources with configurable address space
- **Subnets**: Subnet with delegation to `Microsoft.App/environments` for container apps
- **Route Tables**: Custom routing with next-hop to virtual appliances
- **Network Security Groups**: NSG attached to GitHub subnets
- **VNet Peering**: Bidirectional peering with HMCTS Hub network
- **GitHub Network Settings**: Azure API resource for GitHub network configuration

## 📝 Prerequisites

- Azure subscription access
- Azure DevOps service connection configured
- Access to HMCTS Hub network resources
- Terraform state storage configured in Azure
- GitHub database ID stored in Key Vault

## ⚙️ Configuration

### Required Variables

These variables must be specified in environment-specific `.tfvars` files:

| Variable | Description | Example |
|----------|-------------|---------|
| `hub_vnet_name` | Name of the HUB virtual network | `hmcts-hub-sbox-int` |
| `hub_resource_group_name` | Resource group containing HUB VNet | `hmcts-hub-sbox-int` |
| `hub_subscription_id` | Subscription ID of HUB VNet | `ea3a8c1e-af9d-4108-bc86-a7e2d267f49c` |
| `vnet_address_space` | Address space for the VNet | `10.10.230.0/24` |
| `next_hop_ip_address` | Next hop IP for default route | `10.10.200.36` |
| `env` | Environment identifier | `sbox`, `nonprod`, `prod` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region for resources | `uksouth` |
| `product` | Product/application name | `hub` |
| `builtFrom` | Repository identifier | `hmcts/github-infra` |

## 🔄 CI/CD Pipeline

The repository uses Azure DevOps pipelines for infrastructure deployment.

### Pipeline Triggers

- **Push to main**: Automated plan/apply on main branch
- **Pull Requests**: Plan-only runs for PR validation
- **Scheduled**: Daily at 6 PM (Monday-Friday)

### Pipeline Parameters

- `overrideAction`: Control deployment action
  - `plan` (default): Generate execution plan
  - `apply`: Apply infrastructure changes
  - `destroy`: Destroy infrastructure

### Deployment Stages

1. **Precheck**: Validates prerequisites and credentials
2. **Environment Deployments**: Deploys to configured environments

## 🛠️ Usage

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/hmcts/github-infra.git
   cd github-infra
   ```

2. **Initialize Terraform**
   ```bash
   cd components/network
   terraform init
   ```

3. **Plan changes**
   ```bash
   terraform plan -var-file=../../environments/sbox/sbox.tfvars
   ```

4. **Apply changes** (use with caution)
   ```bash
   terraform apply -var-file=../../environments/sbox/sbox.tfvars
   ```

### Via Azure DevOps

Changes merged to the `main` branch will automatically trigger a plan and apply.

## 📦 Dependencies

This project uses the following modules and providers:

- [terraform-module-azure-virtual-networking](https://github.com/hmcts/terraform-module-azure-virtual-networking) - VNet and subnet management
- [terraform-module-vnet-peering](https://github.com/hmcts/terraform-module-vnet-peering) - VNet peering configuration
- [cnp-azuredevops-libraries](https://github.com/hmcts/cnp-azuredevops-libraries) - Azure DevOps pipeline templates

## 🌍 Environments

- **sbox**: Sandbox environment for testing
- **nonprod**: Non-production environment
- **prod**: Production environment

Each environment has its own configuration in `environments/<env>/<env>.tfvars`.

## 📤 Outputs

The network component exports:

- `github_id`: The GitHub ID from the network settings resource

## 🔧 Post-Deployment Configuration

After the Terraform infrastructure has been successfully deployed, you need to create the network configuration in GitHub and associate it with runner groups.

> **Note**: While the Terraform GitHub provider does not yet have dedicated resources for `network-configurations`, you can use the `github_app_token` data source to automate API calls via `local-exec` provisioners. Track native resource support at [terraform-provider-github](https://github.com/integrations/terraform-provider-github).

### Automation Options

You have three options for completing this configuration:

1. **Semi-Automated (Recommended)**: Use Terraform's `github_app_token` data source with `null_resource` and `local-exec` to make API calls (see Option B below)
2. **Manual via Web UI**: Complete configuration through GitHub's web interface (see Option A below)
3. **Manual via API**: Use curl commands with a personal access token

### Step 1: Retrieve the Network Settings ID

After Terraform applies successfully, retrieve the network settings ID from the output:

```bash
cd components/network
terraform output github_id
```

This will return a value like: `EC486D5D793175D7E3B29C27318D5C1AAE49A7833FC85F2E82C3D2C54AC7D3BA`

Save this value - you'll need it in the next steps.

### Step 2: Create Network Configuration in GitHub

#### Option A: Via GitHub Web UI (Recommended for initial setup)

1. Navigate to your GitHub Enterprise or Organization settings:
   - **Enterprise**: `https://github.com/enterprises/{enterprise-name}/settings/hosted-compute-networking`
   - **Organization**: `https://github.com/organizations/{org-name}/settings/hosted-compute-networking`

2. Click **"New network configuration"** dropdown
3. Select **"Azure private network"**
4. Configure the network:
   - **Name**: `hmcts-{env}-network-config` (e.g., `hmcts-sbox-network-config`)
   - **Azure Virtual Network**: Paste the network settings ID from Step 1
5. Click **"Add Azure Virtual Network"**
6. Click **"Create network configuration"**

#### Option B: Via GitHub REST API

You can also create the network configuration using the GitHub REST API. If you're using GitHub App authentication (recommended), you can leverage Terraform's `github_app_token` data source to generate the token:

**Using GitHub App Authentication (Recommended):**

Add this to your Terraform configuration:

```hcl
# In a separate github-config.tf file or at the end of network.tf

data "github_app_token" "github_token" {
  app_id          = var.github_app_id          # or from env: GITHUB_APP_ID
  installation_id = var.github_app_installation_id  # or from env: GITHUB_APP_INSTALLATION_ID
  pem_file        = var.github_app_pem_file    # or from env: GITHUB_APP_PEM_FILE
}

resource "null_resource" "github_network_configuration" {
  triggers = {
    network_settings_id = jsondecode(azapi_resource.network_settings.output).tags.GitHubId
    env                 = var.env
  }

  provisioner "local-exec" {
    command = <<-EOT
      RESPONSE=$(curl -s -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${data.github_app_token.github_token.token}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/orgs/${var.github_org}/settings/network-configurations \
        -d '{
          "name": "hmcts-${var.env}-network-config",
          "network_settings_ids": ["${jsondecode(azapi_resource.network_settings.output).tags.GitHubId}"],
          "compute_service": "actions"
        }')
      
      echo "Network configuration created:"
      echo "$RESPONSE"
      echo "$RESPONSE" > network-config-${var.env}.json
    EOT
  }

  depends_on = [azapi_resource.network_settings]
}
```

**Using Personal Access Token:**

```bash
# Set your variables
GITHUB_TOKEN="your_github_token"
GITHUB_ORG="your_org_name"
NETWORK_SETTINGS_ID="your_network_settings_id_from_step_1"
ENV="sbox"  # or nonprod, prod

# Create network configuration
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/orgs/${GITHUB_ORG}/settings/network-configurations \
  -d '{
    "name": "hmcts-'${ENV}'-network-config",
    "network_settings_ids": ["'${NETWORK_SETTINGS_ID}'"],
    "compute_service": "actions"
  }'
```

Save the `id` returned in the response - you'll need it for associating with runner groups.

### Complete Terraform Automation Example

If you want to fully automate this process, here's a complete example you can add to your configuration:

```hcl
# variables.tf - Add these variables
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "hmcts"
}

variable "github_app_id" {
  description = "GitHub App ID for API authentication"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_pem_file" {
  description = "GitHub App PEM file contents"
  type        = string
  sensitive   = true
}

# github-automation.tf - Create this new file
data "github_app_token" "automation" {
  app_id          = var.github_app_id
  installation_id = var.github_app_installation_id
  pem_file        = var.github_app_pem_file
}

resource "null_resource" "github_network_config" {
  triggers = {
    network_settings_id = jsondecode(azapi_resource.network_settings.output).tags.GitHubId
    env                 = var.env
    org                 = var.github_org
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      echo "Creating GitHub network configuration..."
      
      RESPONSE=$(curl -s -w "\n%{http_code}" -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${data.github_app_token.automation.token}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/orgs/${var.github_org}/settings/network-configurations \
        -d '{
          "name": "hmcts-${var.env}-network-config",
          "network_settings_ids": ["${jsondecode(azapi_resource.network_settings.output).tags.GitHubId}"],
          "compute_service": "actions"
        }')
      
      HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
      BODY=$(echo "$RESPONSE" | sed '$d')
      
      if [ "$HTTP_CODE" -eq 201 ]; then
        echo "✅ Network configuration created successfully"
        echo "$BODY" | jq '.'
        echo "$BODY" > "${path.module}/network-config-${var.env}.json"
      else
        echo "❌ Failed to create network configuration (HTTP $HTTP_CODE)"
        echo "$BODY" | jq '.' || echo "$BODY"
        exit 1
      fi
    EOT
    
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Note: Network configuration should be deleted via GitHub UI or API"
      echo "Network config ID is in network-config-${self.triggers.env}.json"
    EOT
  }

  depends_on = [azapi_resource.network_settings]
}

output "network_config_file" {
  description = "Path to the network configuration response file"
  value       = "${path.module}/network-config-${var.env}.json"
}
```

**Setting up environment variables for CI/CD:**

```bash
# In your Azure DevOps pipeline or local environment
export GITHUB_APP_ID="your-app-id"
export GITHUB_APP_INSTALLATION_ID="your-installation-id"
export GITHUB_APP_PEM_FILE="$(cat your-app-private-key.pem)"

# Or store in Azure DevOps Library as secure variables
```

**Required permissions for the GitHub App:**

The GitHub App needs the following permissions:
- **Organization permissions**:
  - Actions: Read and write
  - Network configurations: Read and write
  - Self-hosted runners: Read and write

### Step 3: Create or Update Runner Groups

#### Via GitHub Web UI

1. Navigate to Actions runner groups:
   - **Enterprise**: `https://github.com/enterprises/{enterprise-name}/settings/actions/runner-groups`
   - **Organization**: `https://github.com/organizations/{org-name}/settings/actions/runner-groups`

2. Either create a new runner group or edit an existing one:
   - Click **"New runner group"** or **"Edit"** on an existing group
   - Configure the runner group settings (name, visibility, repository access)
   - Under **"Network configurations"**, select the network configuration you created in Step 2
   - Click **"Create group"** or **"Update group"**

#### Via GitHub REST API

```bash
# Set your variables
GITHUB_TOKEN="your_github_token"
GITHUB_ORG="your_org_name"
NETWORK_CONFIG_ID="network_config_id_from_step_2"

# Create a new runner group with network configuration
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runner-groups \
  -d '{
    "name": "hmcts-private-runners",
    "visibility": "all",
    "allows_public_repositories": false,
    "network_configuration_id": "'${NETWORK_CONFIG_ID}'"
  }'
```

### Step 4: Add GitHub-Hosted Runners

1. Navigate to the runner group you configured in Step 3
2. Add GitHub-hosted runners to the group
3. The runners will now use the private network configuration and route traffic through your Azure VNet

For more details, see:
- [GitHub Docs: Configuring private networking for GitHub-hosted runners](https://docs.github.com/en/enterprise-cloud@latest/admin/configuration/configuring-private-networking-for-hosted-compute-products/configuring-private-networking-for-github-hosted-runners-in-your-enterprise)
- [GitHub REST API: Network configurations](https://docs.github.com/en/rest/orgs/network-configurations)
