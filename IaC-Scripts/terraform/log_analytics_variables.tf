# log Analytics workspace variables

# we need create_log_analytics_flag to check if the given la_name is exist or need to create a new one
# this is require because datasource will throw error if the resource is not exist
variable "create_log_analytics_flag" {
  type        = bool
  description = "Create LA or not, provide via la.tfvars"
}

# create_log_analytics_flag is true of false, having LA Name empty means
# nothing is require (neither create or look from data source)
variable "la_name" {
  type        = string
  description = "Log Analytics workspace name, provide via la.tfvars"
}

variable "la_retention_in_days" {
  type        = number
  description = "retention days, provide via la.tfvars"
  default     = 30
}