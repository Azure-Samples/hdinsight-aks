variable "rg_name" {
  type        = string
  description = "the storage account resource group name "
}
variable "location_name" {
  type        = string
  description = "the storage account location/region"
}
variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}
variable "sql_server_name" {
  type        = string
  description = "SQL Server name"
}

variable "create_sql_server_flag" {
  type        = bool
  description = "create or use sql server to create multiple databases for the hive catalog"
}

variable "kv_id" {
  type        = string
  description = "Key Vault Id to store SQL server admin password"
}

variable "kv_sql_server_secret_name" {
  type        = string
  description = "Key Vault secret name to store sql server password"
}

variable "sql_server_admin_user_name" {
  type        = string
  description = "SQL server admin user name"
}