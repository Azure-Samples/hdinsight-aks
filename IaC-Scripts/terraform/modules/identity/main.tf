data "azurerm_user_assigned_identity" "hdi_id_data" {
  count               = !var.create_user_assigned_identity_flag ? 1 : 0
  name                = var.user_assigned_identity_name
  resource_group_name = var.rg_name
}

resource "azurerm_user_assigned_identity" "hdi_id" {
  count               = var.create_user_assigned_identity_flag ? 1 : 0
  location            = var.location_name
  name                = var.user_assigned_identity_name
  resource_group_name = var.rg_name
  tags                = var.tags
}

locals {
  principal_id = var.create_user_assigned_identity_flag? azurerm_user_assigned_identity.hdi_id[0].principal_id : data.azurerm_user_assigned_identity.hdi_id_data[0].principal_id
  client_id    = var.create_user_assigned_identity_flag? azurerm_user_assigned_identity.hdi_id[0].client_id : data.azurerm_user_assigned_identity.hdi_id_data[0].client_id
  resource_id  = var.create_user_assigned_identity_flag? azurerm_user_assigned_identity.hdi_id[0].id : data.azurerm_user_assigned_identity.hdi_id_data[0].id
  tenant_id    = var.create_user_assigned_identity_flag? azurerm_user_assigned_identity.hdi_id[0].tenant_id : data.azurerm_user_assigned_identity.hdi_id_data[0].tenant_id
}
