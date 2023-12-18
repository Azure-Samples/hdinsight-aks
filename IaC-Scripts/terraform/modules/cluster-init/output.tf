# storage module
output "storage_id" {
  value = module.storage_account.storage_id
}
output "storage_name" {
  value = module.storage_account.storage_name
}
output "storage_dfs_host" {
  value = module.storage_account.dfs_host
}
# identity module
output "msi_resource_id" {
  value = module.user_managed_identity.resource_id
}
output "msi_client_id" {
  value = module.user_managed_identity.client_id
}
output "msi_principal_id" {
  value = module.user_managed_identity.user_managed_principal_id
}

output "kv_id" {
  value = length(var.key_vault_name)>0 ? module.key_vault[0].kv_id : ""
}

output "kv_name" {
  value = length(var.key_vault_name)>0 ? module.key_vault[0].kv_name : ""
}

output "sql_server_id" {
  value = length(var.sql_server_name)>0 ? module.sql_server[0].sql_server_id : ""
}

output "sql_server_name" {
  value = length(var.sql_server_name)>0 ? module.sql_server[0].sql_server_name : ""
}