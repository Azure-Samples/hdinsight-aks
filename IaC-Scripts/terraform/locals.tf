locals {
  prefix = var.prefix!="" ? "${var.prefix}_" : var.prefix
  suffix = var.suffix!="" ? "_${var.suffix}" : var.suffix

  # list of tags you would like to apply for your resources
  # you can always override or add more values in respective resource
  tags = {

  }
}