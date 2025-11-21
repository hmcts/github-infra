variable "hub_vnet_name" {
  description = "The name of the HUB virtual network."
  type        = string
}

variable "hub_resource_group_name" {
  description = "The name of the resource group containing the HUB virtual network."
  type        = string
}

variable "hub_subscription_id" {
  description = "The subscription ID containing the HUB virtual network."
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network"
  type        = string
}

variable "next_hop_ip_address" {
  description = "The IP address of the next hop for the default route"
  type        = string
}

variable "env" {
  description = "The environment (e.g., dev, test, prod)"
  type        = string
}

variable "key_vault" {
  description = "Key Vault details containing required secrets."
  type = object({
    name    = string
    rg_name = string
  })
}
