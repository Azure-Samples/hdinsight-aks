variable "trino_cluster_name" {
  description = "trino cluster name"
  type        = string
}
variable "hdi_on_aks_pool_id" {
  description = "HDI on AKS pool id"
  type        = string
}

variable "hdi_arm_api_version" {
  type        = string
  description = "Azure HDI on AKS API version"
}

variable "env" {
  type        = string
  description = "Environment name like dev/test/prod/etc."
}

variable "location_name" {
  type        = string
  description = "location name/region"
}

variable "trino_head_node_sku" {
  type        = string
  description = "Trino head node size, at present it is fixed SKU"
}

variable "trino_head_node_count" {
  type        = number
  description = "Trino head node count, at present it is a fixed number"
}

variable "trino_worker_node_sku" {
  type        = string
  description = "Trino worker node size"
}

variable "trino_worker_node_count" {
  type        = number
  description = "Trino worker node count"
}

variable "trino_secure_shell_node_count" {
  type        = number
  description = "Number of secure shell nodes"
}

variable "cluster_version" {
  type        = string
  description = "Cluster version"
}

variable "trino_version" {
  type        = string
  description = "Trino version"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "create_trino_cluster_flag" {
  type        = bool
  description = "create trino cluster"
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

variable "trino_cluster_default_container" {
  type        = string
  description = "default container for the cluster"
}


variable "use_log_analytics_for_trino" {
  type        = bool
  description = "use LA or not for the trino cluster"
}

variable "la_workspace_id" {
  type        = string
  description = "Log Analytics workspace Id"
}

variable "sql_server_id" {
  type        = string
  description = "SQL database used for the Hive Metastore."
}

variable "trino_hive_enabled_flag" {
  type        = bool
  description = "enable hive for the trino"
}

variable "trino_hive_catalog_name" {
  type = string
  description = "The name of the Hive catalog to be created in the cluster."
}

variable "trino_auto_scale_flag" {
  type        = bool
  description = "enable auto scale for the trino cluster, if yes specify auto scale configuration from trino_auto_scale_config.json"
}

variable "trino_auto_scale_type" {
  type        = string
  description = "auto scale type, it supports only schedule based"
}

variable "trino_graceful_decommission_timeout" {
  type        = number
  description = "This is the maximum time to wait for running containers and applications to complete before transitioning a DECOMMISSIONING node to DECOMMISSIONED. it is useful only when we enable auto scale"
}

variable "trino_hive_db" {
  type        = string
  description = "Trino Hive Database name in case of trino_hive_enabled is enabled"
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