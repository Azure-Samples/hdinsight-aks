# Spark cluster related variables

variable "spark_cluster_name" {
  description = "Spark cluster name"
  type        = string
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

variable "spark_version" {
  type        = string
  description = "Spark version"
}

variable "create_spark_cluster_flag" {
  type        = bool
  description = "create spark cluster"
}

variable "spark_cluster_default_container" {
  type        = string
  description = "default container for the cluster"
}

variable "use_log_analytics_for_spark" {
  type        = bool
  description = "use LA or not for the spark cluster"
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
  default     = 180
}

variable "spark_max_load_based_auto_scale_worker_nodes" {
  type        = number
  description = "spark maximum worker nodes for load based auto scale"
  default     = 0
}

variable "spark_hive_db" {
  type        = string
  description = "Spark Hive Database name in case of spark_hive_enabled is enabled"
}