module "networking" {
  source = "github.com/hmcts/terraform-module-azure-virtual-networking?ref=main"

  env         = var.env
  product     = var.product
  common_tags = module.ctags.common_tags
  component   = "network"
  location    = var.location

  vnets = {
    github = {
      address_space = [var.vnet_address_space]
      subnets = {
        github = {
          address_prefixes = var.vnet_address_space
          delegations = {
            containerapps = {
              service_name = "Microsoft.App/environments"
              actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
            }
          }
        }
      }
    }
  }

  route_tables = {
    rt = {
      subnets = ["github-github"]
      routes = {
        default = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = var.next_hop_ip_address
        }
      }
    }
  }

  network_security_groups = {
    nsg = {
      subnets = ["github-github"]
      rules   = {}
    }
  }
}

module "vnet_peer_hub" {
  source = "github.com/hmcts/terraform-module-vnet-peering?ref=master"
  peerings = {
    source = {
      name           = "${module.networking.vnet_names["github"]}-vnet-${var.env}-to-hub"
      vnet_id        = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${module.networking.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${module.networking.vnet_names["github"]}"
      vnet           = module.networking.vnet_names["github"]
      resource_group = module.networking.resource_group_name
    }
    target = {
      name           = "hub-to-${module.networking.vnet_names["github"]}-vnet-${var.env}"
      vnet           = var.hub_vnet_name
      resource_group = var.hub_resource_group_name
    }
  }

  providers = {
    azurerm.initiator = azurerm
    azurerm.target    = azurerm.hub
  }
}

resource "azapi_resource" "network_settings" {
  type      = "GitHub.Network/networkSettings@2024-04-02"
  name      = "github-network-settings-${var.env}"
  parent_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${module.networking.resource_group_name}"
  location  = var.location

  body = {
    properties = {
      subnetId   = module.networking.subnet_ids["github-github"]
      businessId = data.azurerm_key_vault_secret.github_database_id.value
    }
  }

  response_export_values = ["tags.GitHubId", "name"]
}
