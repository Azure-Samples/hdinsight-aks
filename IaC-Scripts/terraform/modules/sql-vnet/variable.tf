variable "subnet_id" {
  type        = string
  description = "Pass Subnet Id if pool is created in VNet, else empty"
}

variable "sql_server_id" {
  type        = string
  description = "sql server id"
}