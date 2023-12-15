variable "spark_cluster_name" {
  description = "Spark cluster name"
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

variable "spark_head_node_sku" {
  type        = string
  description = "Spark head node size, at present it is fixed SKU"
}

variable "spark_head_node_count" {
  type        = number
  description = "Spark head node count, at present it is a fixed number"
}

variable "spark_worker_node_sku" {
  type        = string
  description = "Spark worker node size"
  default     = "Standard_D8ds_v5"
}

variable "spark_worker_node_count" {
  type        = number
  description = "Spark worker node count"
}

variable "spark_secure_shell_node_count" {
  type        = number
  description = "Number of secure shell nodes"
}

variable "cluster_version" {
  type        = string
  description = "Cluster version"
}

variable "spark_version" {
  type        = string
  description = "Spark version"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "create_spark_cluster_flag" {
  type        = bool
  description = "create spark cluster"
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

variable "spark_cluster_default_container" {
  type        = string
  description = "default container for the cluster"
}


variable "use_log_analytics_for_spark" {
  type        = bool
  description = "use LA or not for the spark cluster"
}

variable "la_workspace_id" {
  type        = string
  description = "Log Analytics workspace Id"
}

variable "sql_server_id" {
  type        = string
  description = "SQL database used for the Hive Metastore."
}

variable "spark_hive_enabled_flag" {
  type        = bool
  description = "enable hive for the spark"
}

variable "spark_auto_scale_type" {
  type        = string
  description = "schedule or load based auto scale"
}

variable "spark_auto_scale_flag" {
  type        = bool
  description = "enable auto scale for the Spark cluster, if yes specify auto scale configuration from spark_auto_scale_type.json"
}

variable "spark_graceful_decommission_timeout" {
  type        = number
  description = "This is the maximum time to wait for running containers and applications to complete before transitioning a DECOMMISSIONING node to DECOMMISSIONED."
}

variable "spark_cooldown_period_for_load_based_autoscale" {
  type        = number
  description = "After an auto scaling event occurs, the amount of time to wait before enforcing another scaling policy. The default value is 180 sec."
}

variable "spark_max_load_based_auto_scale_worker_nodes" {
  type        = number
  description = "spark maximum worker nodes for load based auto scale"
}

variable "spark_hive_db" {
  type        = string
  description = "Spark Hive Database name in case of spark_hive_enabled is enabled"
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