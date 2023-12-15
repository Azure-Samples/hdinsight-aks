variable "key_vault_name" {
  type        = string
  description = "key vault name"
}

variable "create_key_vault_flag" {
  type        = bool
  description = "create or use existing Key Vault"
}