# create or use existing storage
data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "hdi_storage" {
  count               = !var.create_storage_flag? 1 : 0
  name                = var.storage_name
  resource_group_name = var.rg_name
}

# call only if could not find from the data source
resource "azurerm_storage_account" "hdi_storage" {
  count                    = var.create_storage_flag? 1 : 0
  name                     = var.storage_name
  resource_group_name      = var.rg_name
  location                 = var.location_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  tags                     = var.tags
}

locals {
  storage_id = var.create_storage_flag ? azurerm_storage_account.hdi_storage[0].id : data.azurerm_storage_account.hdi_storage[0].id
  dfs_host   = var.create_storage_flag ? azurerm_storage_account.hdi_storage[0].primary_dfs_host : data.azurerm_storage_account.hdi_storage[0].primary_dfs_host
}

# assign Contributor role to the current client config
resource "azurerm_role_assignment" "hdi_storage_contributor_role" {
  scope                = local.storage_id
  for_each             = {for idx, value in toset(var.current_client_storage_permission) : idx=>value}
  role_definition_name = each.value
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_storage_account.hdi_storage]
}


# Assign Storage Blob Data Owner role for User Managed Identity on storage account
resource "azurerm_role_assignment" "hdi_st_role_identity" {
  scope                = local.storage_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.user_managed_object_id
}
