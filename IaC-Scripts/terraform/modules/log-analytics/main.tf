# ideally whenever you call this module you would require
# la_name, rg_name and location_name
data "azurerm_log_analytics_workspace" "hdk_on_aks_la_data" {
  count               = !var.create_log_analytics_flag && length(var.la_name)>0 ?  1 : 0
  name                = var.la_name
  resource_group_name = var.rg_name
}

resource "azurerm_log_analytics_workspace" "hdk_on_aks_la" {
  count               = var.create_log_analytics_flag ?  1 : 0
  name                = var.la_name
  location            = var.location_name
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = var.la_retention_in_days
}

locals {
  name         = var.create_log_analytics_flag ? azurerm_log_analytics_workspace.hdk_on_aks_la[0].name : data.azurerm_log_analytics_workspace.hdk_on_aks_la_data[0].name
  id           = var.create_log_analytics_flag ? azurerm_log_analytics_workspace.hdk_on_aks_la[0].id : data.azurerm_log_analytics_workspace.hdk_on_aks_la_data[0].id
  workspace_id = var.create_log_analytics_flag ? azurerm_log_analytics_workspace.hdk_on_aks_la[0].workspace_id : data.azurerm_log_analytics_workspace.hdk_on_aks_la_data[0].workspace_id
}