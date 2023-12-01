# This is main file to include all modules require to create HDInsight on AKS Pool and Cluster
terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Terraform supports a number of different methods for authenticating to Azure
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_certificate
# In this case we are using Authenticating using managed identities
# You can make necessary changes based on your organization policy
provider "azapi" {
  subscription_id = var.subscription
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Resource group module to create resource group to hold
# HDInsight on AKS Pool and ClusterR
module "resource-group" {
  source        = "./modules/resource-group"
  location_name = var.location_name
  rg_name       = "${local.prefix}${var.rg_name}${local.suffix}"
  tags          = local.tags
}

# This module will setup  the VNet for your cluster and pool, The vnet_rg_name is resource group for the VNet
# If you would like to use your existing VNet and SubNet you can set following variable values in tfvarss
# create_vnet=false, create_subnet=false with existing vnet_name, subnet_name, and resource group name (vnet_rg_name)
# If you would like to create a new VNet and SubNet you can set following variable values in tfvarss
# create_vnet=true, create_subnet=true with new vnet_name, subnet_name, and resource group name (vnet_rg_name)
# If you would like to use existing VNet but new subnet you can set following variable values in tfvarss
# create_vnet=false, create_subnet=true with existing vnet_name, new subnet_name, and resource group name (vnet_rg_name)
# and finally if you don't want to create or use any VNet for your HDInsight on AKS pool, please set
# create_vnet=false, create_subnet=false, vnet_name="", and subnet_name="" (empty string)
module "hdi_on_aks_vnet" {
  source        = "./modules/network"
  vnet_name     = "${local.prefix}${var.vnet_name}${local.suffix}"
  subnet_name   = "${local.prefix}${var.subnet_name}${local.suffix}"
  location_name = var.location_name
  tags          = local.tags
  vnet_rg_name  = var.vnet_rg_name
  create_vnet   = var.create_vnet
  create_subnet = var.create_subnet
  count         = var.vnet_name!="" && var.subnet_name!="" ? 1 : 0
  depends_on    = [module.resource-group]
}

# This module is creates HDInsight cluster pool
# Based on hdi_on_aks_vnet module the pool will be created
# for all supported pool_node_vm_size, please refer HDInsight on AKS documentation on Azure
# managed_resource_group_name is
module "hdi_on_aks_pool" {
  source                      = "./modules/cluster-pool"
  client_id                   = var.client_id
  client_secret               = var.client_secret
  subscription                = var.subscription
  tenant_id                   = var.tenant_id
  hdi_on_aks_pool_name        = "${local.prefix}${var.hdi_on_aks_pool_name}${local.suffix}"
  location_name               = var.location_name
  rg_id                       = module.resource-group.resource_group_id
  tags                        = local.tags
  depends_on                  = [module.resource-group, module.hdi_on_aks_vnet]
  pool_node_vm_size           = var.pool_node_vm_size
  pool_version                = var.pool_version
  managed_resource_group_name = var.managed_resource_group_name
  subnet_id                   = var.subnet_name=="" ? var.empty : module.hdi_on_aks_vnet[0].subnet_id
}

# This module creates user managed identity for the cluster
/*module "user_managed_identity" {
  source                      = "./modules/identity"
  user_assigned_identity_name = var.user_assigned_identity_name
  rg_name                     = module.resource-group.resource_group_name
  location_name               = var.location_name
  tags                        = local.tags
  depends_on                  = [module.resource-group]
}*/

