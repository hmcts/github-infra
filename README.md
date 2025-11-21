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

This project uses the following modules:

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
