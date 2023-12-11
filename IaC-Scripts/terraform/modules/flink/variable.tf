variable "flink_cluster_name" {
  description = "Flink cluster name"
  type        = string
}
variable "hdi_on_aks_pool_id" {
  description = "HDI on AKS pool id"
  type        = string
}

variable "location_name" {
  type        = string
  description = "location name/region"
}

variable "flink_head_node_sku" {
  type        = string
  description = "Flink head node size, at present it is fixed SKU"
}

variable "flink_head_node_count" {
  type        = number
  description = "Flink head node count, at present it is a fixed number"
}

variable "flink_worker_node_sku" {
  type        = string
  description = "Flink worker node size"
  default     = "Standard_D8ds_v5"
}

variable "flink_worker_node_count" {
  type        = number
  description = "Flink worker node count"
}

variable "flink_secure_shell_node_count" {
  type        = number
  description = "Number of secure shell nodes"
}

variable "cluster_version" {
  type        = string
  description = "Cluster version"
}

variable "flink_version" {
  type        = string
  description = "Flink version"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "create_flink_cluster_flag" {
  type        = bool
  description = "create flink cluster"
}

variable "user_managed_client_id" {
  type        = string
  description = "User managed client identity"
}

variable "user_managed_principal_id" {
  type        = string
  description = "User managed identity / principal id"
}

variable "user_managed_resource_id" {
  type        = string
  description = "User managed identity"
}

variable "storage_account_primary_dfs_host" {
  type        = string
  description = "storage account DFS host"
}

variable "storage_account_name" {
  type        = string
  description = "storage account name"
}

variable "flink_cluster_default_container" {
  type        = string
  description = "default container for the cluster"
}

variable "job_manager_conf" {
  type        = map(string)
  description = "Job Manager configuration like CPU, memory, etc."
}

variable "task_manager_conf" {
  type        = map(string)
  description = "Task Manager configuration like CPU, memory, etc."
}

variable "history_server_conf" {
  type        = map(string)
  description = "History server configuration like CPU, memory, etc."
}

variable "use_log_analytics_for_flink" {
  type        = bool
  description = "use LA or not for the flink cluster"
}

variable "la_workspace_id" {
  type        = string
  description = "Log Analytics workspace Id"
}

variable "sql_server_id" {
  type        = string
  description = "SQL server Id"
}

variable "flink_hive_enabled" {
  type        = bool
  description = "enable hive for the flink"
}

variable "flink_hive_db" {
  type        = string
  description = "Flink Hive Database name in case of flink_hive_enabled is enabled"
}

variable "kv_id" {
  type        = string
  description = "Key Vault Id"
}

variable "kv_sql_server_secret_name" {
  type        = string
  description = "Key Vault secret name to store sql server password"
}

variable "sql_server_name" {
  type        = string
  description = "SQL Server name for the hive database"
}

variable "sql_server_admin_user_name" {
  type        = string
  description = "SQL server admin user name"
}