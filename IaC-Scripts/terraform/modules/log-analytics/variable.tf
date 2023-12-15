variable "create_log_analytics_flag" {
  type        = bool
  description = "Create LA or not"
}
variable "la_name" {
  type        = string
  description = "Log Analytics workspace name"
}
variable "location_name" {
  type        = string
  description = "Location/Region"
}
variable "rg_name" {
  type        = string
  description = "Resource group where to create the LA"
}
variable "la_retention_in_days" {
  type        = number
  description = "retention days"
}