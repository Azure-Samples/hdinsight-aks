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

# Variables for HDI on AKS resources
variable "location_name" {
  type        = string
  description = "location/region name"
}

variable "rg_name" {
  type        = string
  description = "resource group name for the HDI on AKS"
}

variable "create_rg_for_pool" {
  type        = bool
  description = "Flag to indicate to create a resource group or not for the HDInsight on AKS"
}


/*variable "user_assigned_identity_name" {
  type        = string
  description = "user assigned identity used for the cluster"
}*/

variable "hdi_on_aks_pool_name" {
  type        = string
  description = "Pool name for HDI on AKS, use HDInsight on AKS documentation for the naming rules"
}

variable "managed_resource_group_name" {
  type        = string
  description = "Provide a name for managed resource group. It holds ancillary resources created by HDInsight on AKS."
  default     = ""
}

# VNet name - pass empty value from tfvars if you don't want to create pool in VNet
variable "vnet_name" {
  type        = string
  description = "VNet name"
  default     = ""
}

# would you like to use existing VNet or create a new one. In both case it will use vnet_name
# if vnet_name is empty the network module will be skipped
variable "create_vnet" {
  type        = bool
  description = "create vnet or not, if it is existing then false (0) else true (1)"
  default     = false
}

variable "vnet_rg_name" {
  type        = string
  description = "VNet resource group name, where VNet should be created or exist"
}

# Subnet name - pass empty value from tfvars if you don't want to create pool in VNet
variable "subnet_name" {
  type        = string
  description = "Subnet name"
  default     = ""
}

# would you like to use existing Subnet or create a new one. In both case it will use subnet_name
# if subnet_name is empty the network module will be skipped
variable "create_subnet" {
  type        = bool
  description = "create subnet or not, if it is existing then false (0) else true (1)"
  default     = false
}

variable "pool_version" {
  type        = string
  description = "The version of the Azure HDInsight on AKS cluster pool to create."
  default     = "1.0"
}

variable empty {
  default = ""
}

variable "pool_node_vm_size" {
  type        = string
  description = "VM SKU selected for the cluster pool."
}