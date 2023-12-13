output "vnet_id" {
  value = var.create_vnet_flag ? azurerm_virtual_network.hdi_vnet[0].id : data.azurerm_virtual_network.vnet[0].id
}

output "vnet_name" {
  value = var.create_vnet_flag ? azurerm_virtual_network.hdi_vnet[0].name : data.azurerm_virtual_network.vnet[0].name
}

output "subnet_id" {
  value = var.create_subnet_flag ? azurerm_subnet.hdi_default_subnet_default[0].id : data.azurerm_subnet.subnet[0].id
}

output "subnet_name" {
  value = var.create_subnet_flag ? azurerm_subnet.hdi_default_subnet_default[0].name : data.azurerm_subnet.subnet[0].name
}
