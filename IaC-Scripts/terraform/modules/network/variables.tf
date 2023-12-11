variable "location_name" {
  type        = string
  description = "location/region name"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "vnet_name" {
  type        = string
  description = "VNet Name for your pool"
}

variable "subnet_name" {
  type        = string
  description = "Subnet Name for your pool"
}

variable "vnet_rg_name" {
  type        = string
  description = "VNet resource group name, where VNet should be created or exist"
}

variable "create_vnet_flag" {
  type        = bool
  description = "create vnet or not, if it is existing then false (0) else true (1)"
}

variable "create_subnet_flag" {
  type        = bool
  description = "create subnet or not, if it is existing then false (0) else true (1)"
}