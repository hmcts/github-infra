# Sandbox Environment Variables

# Required Variables
hub_vnet_name           = "hmcts-hub-sbox-int"
hub_resource_group_name = "hmcts-hub-sbox-int"
hub_subscription_id     = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
vnet_address_space      = "10.10.230.0/24"
next_hop_ip_address     = "10.10.200.36"
env                     = "sbox"

key_vault = {
  name    = "hmcts-infra-dmz-nonprodi"
  rg_name = "hmcts-infra-dmz-nonprodi"
}
