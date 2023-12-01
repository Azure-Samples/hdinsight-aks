# Check if resource group is exist in the case of create_rg_for_pool=false
data "azurerm_resource_group" "pool_rg" {
  count    = !var.create_rg_for_pool ? 1 : 0
  name     = var.rg_name
}

resource "azurerm_resource_group" "pool_resource_group" {
  count    = var.create_rg_for_pool ? 1 : 0
  name     = var.rg_name
  location = var.location_name
  tags     = var.tags
}