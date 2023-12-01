# This module creates user managed identity for the cluster
module "user_managed_identity" {
  source                      = "../identity"
  user_assigned_identity_name = var.user_assigned_identity_name
  rg_name                     = var.rg_name
  location_name               = var.location_name
  tags                        = var.tags
}