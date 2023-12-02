variable "rg_name" {
  type = string
  description = "resource group name"
}

variable "location_name" {
  type        = string
  description = "location name/region"
}

variable "user_assigned_identity_name" {
  type = string
  description = "user assigned identity used for the cluster"
}

variable "tags" {
  type = map(string)
  description = "list of tags for resources"
}