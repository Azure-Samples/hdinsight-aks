data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "hdi_on_aks_kv_data" {
  count               = !var.create_key_vault_flag ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.rg_name
}

resource "azurerm_key_vault" "hdi_on_aks_kv" {
  count               = var.create_key_vault_flag ? 1 : 0
  name                = var.key_vault_name
  location            = var.location_name
  resource_group_name = var.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "Backup",
      "Delete",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]
  }
  tags = var.tags
}

locals {
  kv_id   = var.create_key_vault_flag ? azurerm_key_vault.hdi_on_aks_kv[0].id : data.azurerm_key_vault.hdi_on_aks_kv_data[0].id
  kv_name = var.create_key_vault_flag ? azurerm_key_vault.hdi_on_aks_kv[0].id : data.azurerm_key_vault.hdi_on_aks_kv_data[0].name
}

resource "azurerm_key_vault_access_policy" "hdi_kv_access_policy" {
  key_vault_id       = local.kv_id
  tenant_id          = var.user_managed_tenant_id
  object_id          = var.user_managed_object_id
  secret_permissions = [
    "Get",
    "Backup",
    "Delete",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set"
  ]
}