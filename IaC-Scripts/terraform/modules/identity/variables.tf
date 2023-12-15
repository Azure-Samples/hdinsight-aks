variable "rg_name" {
  type        = string
  description = "resource group name"
}

variable "location_name" {
  type        = string
  description = "location name/region"
}

variable "user_assigned_identity_name" {
  type        = string
  description = "user assigned identity used for the cluster"
}

variable "create_user_assigned_identity_flag" {
  type        = bool
  description = "create or use existing user assigned identity (user_assigned_identity_name)"
}

variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}
