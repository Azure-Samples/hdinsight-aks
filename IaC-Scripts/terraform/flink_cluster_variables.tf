# Flink cluster related variables

variable "flink_cluster_name" {
  description = "Flink cluster name"
  type        = string
}

variable "flink_head_node_sku" {
  type        = string
  description = "Flink head node size, at present it is fixed SKU"
  default     = "Standard_D8ds_v5"
}

variable "flink_head_node_count" {
  type        = number
  description = "Flink head node count, at present it is a fixed number"
  default     = 2
}

variable "flink_worker_node_sku" {
  type        = string
  description = "Flink worker node size, pass from flink.tfvars file"
  default     = "Standard_D8ds_v5"
}

variable "flink_worker_node_count" {
  type        = number
  description = "Flink worker node count, pass from flink.tfvars file"
  default     = 3
}

variable "flink_secure_shell_node_count" {
  type        = number
  description = "Number of secure shell nodes, pass from flink.tfvars file"
  default     = 0
}

variable "flink_version" {
  type        = string
  description = "Flink version, change if HDInsight releases new versions"
  default     = "1.16.0"
}

variable "create_flink_cluster_flag" {
  type        = bool
  description = "create flink cluster, we need to pass from flink.tfvars file"
}

variable "flink_cluster_default_container" {
  type        = string
  description = "default container for the cluster, pass from flink.tfvars file"
}

variable "job_manager_conf" {
  type        = map(string)
  description = "Job Manager configuration like CPU, memory, etc, pass from flink.tfvars file"
}

variable "task_manager_conf" {
  type        = map(string)
  description = "Task Manager configuration like CPU, memory, etc, pass from flink.tfvars file"
}

variable "history_server_conf" {
  type        = map(string)
  description = "History server configuration like CPU, memory, etc, pass from flink.tfvars file"
}

variable "use_log_analytics_for_flink" {
  type        = bool
  description = "use LA or not for the flink cluster"
}

variable "flink_hive_enabled" {
  type        = bool
  description = "enable hive for the flink"
}

variable "flink_hive_db" {
  type        = string
  description = "Flink Hive Database name in case of flink_hive_enabled is enabled"
}