module "ctags" {
  source = "github.com/hmcts/terraform-module-common-tags"

  builtFrom   = var.builtFrom
  environment = var.env
  product     = var.product
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azurerm_key_vault" "hub_infra_kv" {
  name                = "hmcts-infra-dmz-${var.env}-int"
  resource_group_name = "hmcts-infra-dmz-${var.env}-int"
}

data "azurerm_key_vault_secret" "github_database_id" {
  name         = "github-database-id"
  key_vault_id = data.azurerm_key_vault.hub_infra_kv.id
}
