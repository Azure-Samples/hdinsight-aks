# Check if resource group is exist in the case of create_rg_for_pool_flag=false
data "azurerm_resource_group" "pool_rg" {
  count = !var.create_rg_for_pool_flag ? 1 : 0
  name  = var.rg_name
}

resource "azurerm_resource_group" "pool_resource_group" {
  count    = var.create_rg_for_pool_flag ? 1 : 0
  name     = var.rg_name
  location = var.location_name
  tags     = var.tags
}

locals {
  rg_id   = var.create_rg_for_pool_flag ? azurerm_resource_group.pool_resource_group[0].id : data.azurerm_resource_group.pool_rg[0].id
  rg_name = var.create_rg_for_pool_flag ? azurerm_resource_group.pool_resource_group[0].name : data.azurerm_resource_group.pool_rg[0].name
}