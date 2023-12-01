resource "azurerm_resource_group" "pool_resource_group" {
  name     = var.rg_name
  location = var.location_name
}