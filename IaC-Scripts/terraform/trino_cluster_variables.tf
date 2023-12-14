# Trino cluster related variables

variable "trino_cluster_name" {
  description = "Trino cluster name"
  type        = string
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
  description = "Trino worker node size, pass from trino.tfvars file"
  default     = "Standard_D8ds_v5"
}

variable "trino_worker_node_count" {
  type        = number
  description = "Trino worker node count, pass from trino.tfvars file"
}

variable "trino_secure_shell_node_count" {
  type        = number
  description = "Number of secure shell nodes, pass from trino.tfvars file"
}

variable "trino_version" {
  type        = string
  description = "Trino version, change if HDInsight releases new versions"
}

variable "create_trino_cluster_flag" {
  type        = bool
  description = "create trino cluster, we need to pass from trino.tfvars file"
}

variable "trino_cluster_default_container" {
  type        = string
  description = "default container for the cluster, pass from trino.tfvars file"
}

variable "use_log_analytics_for_trino" {
  type        = bool
  description = "use LA or not for the trino cluster"
}

variable "trino_auto_scale_flag" {
  type        = bool
  description = "enable auto scale for the trino cluster, if yes specify auto scale configuration from trino_auto_scale_config.json"
}

variable "trino_auto_scale_type" {
  type        = string
  description = "auto scale type, it supports only schedule based"
  default     = "scheduleBased"
}

variable "trino_graceful_decommission_timeout" {
  type        = number
  description = "This is the maximum time to wait for running containers and applications to complete before transitioning a DECOMMISSIONING node to DECOMMISSIONED. it is useful only when we enable auto scale"
}

variable "trino_hive_enabled_flag" {
  type        = bool
  description = "enable hive for the trino"
}

variable "trino_hive_catalog_name" {
  type        = string
  description = "The name of the Hive catalog to be created in the cluster."
}

variable "trino_hive_db" {
  type        = string
  description = "Trino Hive Database name in case of trino_hive_enabled is enabled"
}