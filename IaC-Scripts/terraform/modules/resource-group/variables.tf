variable "rg_name" {
  type = string
  description = "resource group name"
}

variable "location_name" {
  type = string
  description = "location/region name"
}

variable "tags" {
  type = map(string)
  description = "list of tags for resources"
}