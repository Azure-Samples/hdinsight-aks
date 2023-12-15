variable "rg_name" {
  type        = string
  description = "resource group name"
}

variable "location_name" {
  type        = string
  description = "location name/region"
}

variable "user_assigned_identity_name" {
  type        = string
  description = "user assigned identity used for the cluster"
}

variable "create_user_assigned_identity_flag" {
  type        = bool
  description = "create or use existing user assigned identity (user_assigned_identity_name)"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "storage_name" {
  type        = string
  description = "the storage account to associate with the cluster"
}

variable "create_storage_flag" {
  type        = bool
  description = "should use existing storage or create a new one"
}

variable "key_vault_name" {
  type        = string
  description = "key vault name"
}

variable "create_key_vault_flag" {
  type        = bool
  description = "create or use existing Key Vault"
}

variable "sql_server_name" {
  type        = string
  description = "SQL Server name"
}

variable "kv_sql_server_secret_name" {
  type        = string
  description = "Key Vault secret name to store sql server password"
}

variable "create_sql_server_flag" {
  type        = bool
  description = "create or use sql server to create multiple databases for the hive catalog"
}

variable "sql_server_admin_user_name" {
  type        = string
  description = "SQL server admin user name"
}