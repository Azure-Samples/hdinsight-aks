# This module creates user managed identity for the cluster
module "user_managed_identity" {
  source                             = "../identity"
  user_assigned_identity_name        = var.user_assigned_identity_name
  create_user_assigned_identity_flag = var.create_user_assigned_identity_flag
  rg_name                            = var.rg_name
  location_name                      = var.location_name
  tags                               = var.tags
}

module "storage_account" {
  source                 = "../storage"
  storage_name           = var.storage_name
  rg_name                = var.rg_name
  location_name          = var.location_name
  create_storage_flag    = var.create_storage_flag
  user_managed_object_id = module.user_managed_identity.user_managed_principal_id
  tags                   = var.tags
  depends_on             = [module.user_managed_identity]
}

# call Key Vault only when key_vault_name is not empty
module "key_vault" {
  count                     = var.key_vault_name!="" ? 1 : 0
  source                    = "../key-vault"
  location_name             = var.location_name
  rg_name                   = var.rg_name
  create_key_vault_flag     = var.create_key_vault_flag
  key_vault_name            = var.key_vault_name
  tags                      = var.tags
  user_managed_principal_id = module.user_managed_identity.user_managed_principal_id
  user_managed_tenant_id    = module.user_managed_identity.user_managed_tenant_id
  depends_on                = [module.user_managed_identity]
}

# call sql server when sql_server_name is not empty
module "sql_server" {
  count                      = var.sql_server_name!="" ? 1 : 0
  source                     = "../sql-database"
  location_name              = var.location_name
  rg_name                    = var.rg_name
  create_sql_server_flag     = var.create_sql_server_flag
  sql_server_name            = var.sql_server_name
  # key vault to store secret
  kv_id                      = var.key_vault_name!="" ? module.key_vault[0].kv_id : ""
  kv_sql_server_secret_name  = var.kv_sql_server_secret_name
  # sql server admin user name
  sql_server_admin_user_name = var.sql_server_admin_user_name
  tags                       = var.tags
  depends_on                 = [module.key_vault]
}