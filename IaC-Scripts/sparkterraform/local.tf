locals {
  prefix = length(var.prefix)>0 ? "${var.prefix}_" : var.prefix
  suffix = length(var.suffix)>0 ? "_${var.suffix}" : var.suffix
  tags   = {

  }
}