variable "hdi_on_aks_pool_name" {
  type        = string
  description = "Pool name for HDI on AKS"
}

variable "managed_resource_group_name" {
  type        = string
  description = "HDI on AKS pool managed resource group name"
}

variable "rg_id" {
  type        = string
  description = "resource group id"
}

variable "rg_name" {
  type        = string
  description = "resource group name for the HDI on AKS"
}

variable "pool_version" {
  type        = string
  description = "The version of the Azure HDInsight on AKS cluster pool to create."
}

variable "location_name" {
  type        = string
  description = "location/region name"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "pool_node_vm_size" {
  type        = string
  description = "VM SKU selected for the cluster pool."
}

variable "subnet_id" {
  type        = string
  description = "SubNet Id"
}

variable "create_log_analytics_flag" {
  type        = bool
  description = "Create LA or not"
}
variable "la_name" {
  type        = string
  description = "Log Analytics workspace name"
}

variable "la_retention_in_days" {
  type        = number
  description = "retention days"
}