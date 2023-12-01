output "resource_group_name" {
  value = var.rg_name
}

output "resource_group_id" {
  value = var.create_rg_for_pool ? azurerm_resource_group.pool_resource_group[0].id : data.azurerm_resource_group.pool_rg[0].id
}