# checks if create_vnet is false means it is existing one and
# This module has pre-validation on vnet_name and subnet_name, if they are not empty
# then only it will be invoked

# we don't need to create a new vnet if create_vnet is false
data "azurerm_virtual_network" "vnet" {
  count               = !var.create_vnet ? 1 : 0
  name                = var.vnet_name
  resource_group_name = var.vnet_rg_name
}

# checks if create_subnet is false means it is existing one and
# we don't need to create a new subnet
data "azurerm_subnet" "subnet" {
  count                = !var.create_subnet ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = var.vnet_rg_name
  virtual_network_name = var.vnet_name
}


# create VNet if create_vnet is true
resource "azurerm_virtual_network" "hdi_vnet" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  location            = var.location_name
  resource_group_name = var.vnet_rg_name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# create SubNet if create_subnet is true
resource "azurerm_subnet" "hdi_default_subnet_default" {
  count                = var.create_subnet ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = var.vnet_rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.KeyVault", "Microsoft.Storage"]
  depends_on           = [azurerm_virtual_network.hdi_vnet]
}