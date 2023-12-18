locals {
  prefix = length(var.prefix)>0 ? "${var.prefix}_" : var.prefix
  suffix = length(var.suffix)>0 ? "_${var.suffix}" : var.suffix

  # list of tags you would like to apply for your resources
  # you can always override or add more values in respective resource
  tags = {

  }
}