# This is main file to include all modules require to create HDInsight on AKS Pool and Cluster
terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.83.0"
    }
  }
}

# Terraform supports a number of different methods for authenticating to Azure
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
# In this case we are using Authenticating using Azure CLI
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli
# You can make necessary changes based on your organization policy
provider "azapi" {

}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Resource group module to create resource group to hold
# HDInsight on AKS Pool and ClusterR
module "resource-group" {
  source                  = "./modules/resource-group"
  location_name           = var.location_name
  rg_name                 = "${local.prefix}${var.rg_name}${local.suffix}"
  create_rg_for_pool_flag = var.create_rg_for_pool_flag
  tags                    = local.tags
}

# This module will setup  the VNet for your cluster and pool, The vnet_rg_name is resource group for the VNet
# If you would like to use your existing VNet and SubNet you can set following variable values in tfvarss
# create_vnet_flag=false, create_subnet_flag=false with existing vnet_name, subnet_name, and resource group name (vnet_rg_name)
# If you would like to create a new VNet and SubNet you can set following variable values in tfvarss
# create_vnet_flag=true, create_subnet_flag=true with new vnet_name, subnet_name, and resource group name (vnet_rg_name)
# If you would like to use existing VNet but new subnet you can set following variable values in tfvarss
# create_vnet_flag=false, create_subnet_flag=true with existing vnet_name, new subnet_name, and resource group name (vnet_rg_name)
# and finally if you don't want to create or use any VNet for your HDInsight on AKS pool, please set
# create_vnet_flag=false, create_subnet_flag=false, vnet_name="", and subnet_name="" (empty string)
module "hdi_on_aks_vnet" {
  source             = "./modules/network"
  vnet_name          = var.vnet_name
  subnet_name        = var.subnet_name
  location_name      = var.location_name
  tags               = local.tags
  vnet_rg_name       = var.vnet_rg_name
  create_vnet_flag   = var.create_vnet_flag
  create_subnet_flag = var.create_subnet_flag
  count              = var.vnet_name!="" && var.subnet_name!="" ? 1 : 0
  depends_on         = [module.resource-group]
}

# This module is creates HDInsight cluster pool
# Based on hdi_on_aks_vnet module the pool will be created
# for all supported pool_node_vm_size, please refer HDInsight on AKS documentation on Azure
# managed_resource_group_name is
module "hdi_on_aks_pool" {
  source                      = "./modules/cluster-pool"
  hdi_on_aks_pool_name        = var.hdi_on_aks_pool_name
  location_name               = var.location_name
  rg_id                       = module.resource-group.resource_group_id
  tags                        = local.tags
  depends_on                  = [module.resource-group, module.hdi_on_aks_vnet]
  pool_node_vm_size           = var.pool_node_vm_size
  pool_version                = var.pool_version
  managed_resource_group_name = var.managed_resource_group_name
  subnet_id                   = var.subnet_name=="" ? "" : module.hdi_on_aks_vnet[0].subnet_id
  create_log_analytics_flag   = var.create_log_analytics_flag
  la_name                     = var.la_name
  la_retention_in_days        = var.la_retention_in_days
  rg_name                     = module.resource-group.resource_group_name
}

module "cluster_init" {
  source                             = "./modules/cluster-init"
  storage_name                       = var.storage_name
  create_storage_flag                = var.create_storage_flag
  user_assigned_identity_name        = "${local.prefix}${var.user_assigned_identity_name}${local.suffix}"
  create_user_assigned_identity_flag = var.create_user_assigned_identity_flag
  location_name                      = var.location_name
  rg_name                            = module.resource-group.resource_group_name
  # key vault to store secret
  create_key_vault_flag              = var.create_key_vault_flag
  key_vault_name                     = var.key_vault_name
  # sql server details
  create_sql_server_flag             = var.create_sql_server_flag
  sql_server_name                    = var.sql_server_name
  sql_server_admin_user_name         = var.sql_server_admin_user_name
  kv_sql_server_secret_name          = var.kv_sql_server_secret_name
  tags                               = local.tags
  depends_on                         = [module.hdi_on_aks_pool]

}

## manage rules for allowing traffic between an Azure SQL server and a subnet of a virtual network only
## if Subnet is not defined and sql server is not used this module will not do anything
module "sql-vnet" {
  count         = (var.subnet_name!="" &&  var.sql_server_name!="") ? 1 : 0
  source        = "./modules/sql-vnet"
  sql_server_id = module.cluster_init.sql_server_id
  subnet_id     = module.hdi_on_aks_vnet[0].subnet_id
}

# Allows you to manage rules for allowing traffic between an Azure SQL server and a subnet of a virtual network.
/*resource "azurerm_mssql_firewall_rule" "metastore_server_rule" {
  count            = (var.subnet_name!="" &&  var.sql_server_name!="") ? 1 : 0
  name             = "AllowAzureServices"
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
  server_id        = module.cluster_init.sql_server_id
}

resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  count     = (var.subnet_name!="" &&  var.sql_server_name!="") ? 1 : 0
  name      = "sql-vnet-rule"
  server_id = module.cluster_init.sql_server_id
  subnet_id = module.hdi_on_aks_vnet[0].subnet_id
}*/

module "flink_cluster" {
  source                           = "./modules/flink"
  flink_cluster_default_container  = var.flink_cluster_default_container
  cluster_version                  = var.cluster_version
  create_flink_cluster_flag        = var.create_flink_cluster_flag
  flink_cluster_name               = var.flink_cluster_name
  flink_version                    = var.flink_version
  hdi_on_aks_pool_id               = module.hdi_on_aks_pool.pool_id
  location_name                    = var.location_name
  # flink default storage
  storage_account_primary_dfs_host = module.cluster_init.storage_dfs_host
  storage_account_name             = module.cluster_init.storage_name
  user_managed_client_id           = module.cluster_init.msi_client_id
  user_managed_principal_id        = module.cluster_init.msi_principal_id
  user_managed_resource_id         = module.cluster_init.msi_resource_id
  # flink worker and head node configuration
  flink_head_node_count            = var.flink_head_node_count
  flink_head_node_sku              = var.flink_head_node_sku
  flink_worker_node_count          = var.flink_worker_node_count
  flink_secure_shell_node_count    = var.flink_secure_shell_node_count
  # flink configuration
  history_server_conf              = var.history_server_conf
  job_manager_conf                 = var.job_manager_conf
  task_manager_conf                = var.task_manager_conf
  tags                             = local.tags
  # log analytics
  la_workspace_id                  = module.hdi_on_aks_pool.log_analytics_workspace_id
  use_log_analytics_for_flink      = var.use_log_analytics_for_flink
  # flink hive enabled
  flink_hive_db                    = var.flink_hive_db
  flink_hive_enabled               = var.flink_hive_enabled
  # sql server details, if name is empty that means no sql server is defined
  sql_server_id                    = var.sql_server_name!="" ? module.cluster_init.sql_server_id : ""
  sql_server_admin_user_name       = var.sql_server_admin_user_name
  sql_server_name                  = module.cluster_init.sql_server_name
  # key vault for SQL server secret
  kv_id                            = var.key_vault_name !="" ? module.cluster_init.kv_id : ""
  kv_sql_server_secret_name        = var.kv_sql_server_secret_name
  depends_on                       = [module.cluster_init]
}