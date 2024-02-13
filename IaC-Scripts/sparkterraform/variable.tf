variable "subscription_id" {
  type        = string
  description = "Subscription Id"
}

variable "prefix" {
  type        = string
  default     = ""
  description = "prefix all resource name"
}

variable "suffix" {
  type        = string
  default     = ""
  description = "suffix all resource name"
}

variable "rg_name" {
  type        = string
  description = "resource group name for the HDI on AKS"
}

variable "vnet_name" {
  type        = string
  description = "VNet Name for your pool"
}

variable "subnet_name" {
  type        = string
  description = "Subnet Name for your pool"
  default     = "default"
}

variable "hdi_on_aks_pool_name" {
  type        = string
  description = "Pool name for HDI on AKS"
}

variable "pool_version" {
  type        = string
  description = "The version of the Azure HDInsight on AKS cluster pool to create."
  default     = "1.1"
}

variable "pool_node_vm_size" {
  type        = string
  description = "VM SKU selected for the cluster pool."
}

variable "user_assigned_identity_name" {
  type        = string
  description = "user assigned identity used for the cluster"
}

variable "spark_cluster_name" {
  description = "Spark cluster name"
  type        = string
}

# change only when API version changes
variable "hdi_arm_api_version" {
  type        = string
  description = "Azure HDI on AKS API version"
  default     = "2023-06-01-preview"
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
  default     = "1.1.0"
  description = "Cluster version"
}

variable "spark_version" {
  type        = string
  description = "Spark version"
}


variable "storage_account_name" {
  type        = string
  description = "storage account name"
}

variable "spark_cluster_default_container" {
  type        = string
  description = "default container for the cluster"
}

variable "current_client_storage_permission" {
  type        = list(string)
  description = "List of roles assign to the storage account for the current client"
  default     = ["Storage Blob Data Contributor", "Contributor"]
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