variable "rg_name" {
  type        = string
  description = "the storage account resource group name "
}
variable "location_name" {
  description = "the storage account location/region"
  type        = string
}
variable "tags" {
  type        = map(string)
  description = "list of tags for resources"
}
variable "key_vault_name" {
  type        = string
  description = "key vault name"
}

variable "create_key_vault_flag" {
  type        = bool
  description = "create or use existing Key Vault"
}

variable "user_managed_principal_id" {
  type        = string
  description = "Id for User managed identity / principal id"
}

variable "user_managed_tenant_id" {
  type        = string
  description = "Id for User managed tenant id"
}

