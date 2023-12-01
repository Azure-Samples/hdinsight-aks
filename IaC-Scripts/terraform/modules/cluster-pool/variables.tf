variable "tenant_id" {
  type        = string
  description = "azure tenant id"
}

variable "subscription" {
  type        = string
  description = "azure subscription"
}


variable "client_id" {
  type        = string
  sensitive   = true
  description = "authenticate terraform using service principal- SP app id/client id"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "authenticate terraform using service principal- SP secret"
}

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