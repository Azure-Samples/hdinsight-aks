variable "storage_name" {
  type        = string
  description = "the storage account to associate with the cluster"
}
variable "rg_name" {
  default = "the storage account resource group name "
}
variable "location_name" {
  default = "the storage account location/region"
}
variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}

variable "create_storage_flag" {
  type        = bool
  description = "should use existing storage or create a new one"
}

variable "current_client_storage_permission" {
  type        = list(string)
  description = "List of roles assign to the storage account for the current client"
  default     = ["Storage Blob Data Contributor", "Contributor"]
}

variable "user_managed_object_id" {
  type        = string
  description = "Id for User managed identity / principal id"
}