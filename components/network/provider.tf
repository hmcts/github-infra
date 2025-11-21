terraform {
  required_version = ">= 1.13.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.53.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.7.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.hub_subscription_id
}
