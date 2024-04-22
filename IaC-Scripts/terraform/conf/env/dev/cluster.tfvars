# List of values for cluster pool, storage, and Key Vault
# Storage and Managed identities are created in rg_name (resource group where pool is created)
# Identity name will be prefix and suffix at runtime
# Storage name will not be prefix and suffix, use unique name
# https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview#storage-account-name
user_assigned_identity_name        = "terraformtest"
create_user_assigned_identity_flag = true
# Storage related variable values
storage_name                       = "tfonakssteststoragedemo"
# create storage account or use existing one with given storage_name name
create_storage_flag                = true
# key vault name
key_vault_name                     = "hdi-on-aks-kv"
# create key vault or use existing one if Key Vault Name is empty then value is irrelevant
create_key_vault_flag              = true
# Create or use existing SQL server, if sql_server_name name is empty that means skip the sql server module
sql_server_name                    = "terraform-hdi-on-aks"
create_sql_server_flag             = true