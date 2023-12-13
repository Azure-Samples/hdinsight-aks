variable "rg_name" {
  type        = string
  description = "resource group name"
}

variable "location_name" {
  type        = string
  description = "location/region name"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "create_rg_for_pool_flag" {
  type        = bool
  description = "Flag to indicate to create a resource group or not for the HDInsight on AKS"
}
