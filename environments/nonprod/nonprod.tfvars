# NonProd Environment Variables

# Required Variables
hub_vnet_name           = "hmcts-hub-nonprodi"
hub_resource_group_name = "hmcts-hub-nonprodi"
hub_subscription_id     = "fb084706-583f-4c9a-bdab-949aac66ba5c"
vnet_address_space      = "10.10.231.0/24"
next_hop_ip_address     = "10.11.72.36"
env                     = "nonprod"

key_vault = {
  name    = "hmcts-hub-infra-nonprodi"
  rg_name = "hmcts-hub-infra-nonprodi"
}
