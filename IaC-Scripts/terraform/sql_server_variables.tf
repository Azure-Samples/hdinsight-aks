variable "sql_server_name" {
  type        = string
  description = "SQL Server name"
}

variable "create_sql_server_flag" {
  type        = bool
  description = "create or use sql server to create multiple databases for the hive catalog"
}

variable "kv_sql_server_secret_name" {
  type        = string
  description = "Key Vault secret name to store sql server password"
  default     = "sqlhditerraform"
}

variable "sql_server_admin_user_name" {
  type        = string
  description = "SQL server admin user name"
  default     = "hditerraform"
}