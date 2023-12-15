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
  features {
    resource_group {
      # keep false if you want to delete resource group managed by terraform, this will delete any resources
      # created outside of terraform state
      prevent_deletion_if_contains_resources = false
    }
  }
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
  depends_on         = [
    module.resource-group
  ]
}

# This module is creates HDInsight cluster pool
# Based on hdi_on_aks_vnet module the pool will be created
# for all supported pool_node_vm_size, please refer HDInsight on AKS documentation on Azure
# managed_resource_group_name is
module "hdi_on_aks_pool" {
  source                      = "./modules/cluster-pool"
  hdi_on_aks_pool_name        = var.hdi_on_aks_pool_name
  hdi_arm_api_version         = var.hdi_arm_api_version
  location_name               = var.location_name
  rg_id                       = module.resource-group.resource_group_id
  tags                        = local.tags
  pool_node_vm_size           = var.pool_node_vm_size
  pool_version                = var.pool_version
  managed_resource_group_name = var.managed_resource_group_name
  subnet_id                   = var.subnet_name=="" ? "" : module.hdi_on_aks_vnet[0].subnet_id
  create_log_analytics_flag   = var.create_log_analytics_flag
  la_name                     = var.la_name
  la_retention_in_days        = var.la_retention_in_days
  rg_name                     = module.resource-group.resource_group_name
  depends_on                  = [
    module.resource-group, module.hdi_on_aks_vnet
  ]
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

module "flink_cluster" {
  source                              = "./modules/flink"
  env                                 = var.env
  cluster_version                     = var.cluster_version
  hdi_arm_api_version                 = var.hdi_arm_api_version
  create_flink_cluster_flag           = var.create_flink_cluster_flag
  hdi_on_aks_pool_id                  = module.hdi_on_aks_pool.pool_id
  location_name                       = var.location_name
  # flink default storage
  storage_account_primary_dfs_host    = module.cluster_init.storage_dfs_host
  storage_account_name                = module.cluster_init.storage_name
  flink_cluster_default_container     = var.flink_cluster_default_container
  # MSI related
  user_managed_client_id              = module.cluster_init.msi_client_id
  user_managed_principal_id           = module.cluster_init.msi_principal_id
  user_managed_resource_id            = module.cluster_init.msi_resource_id
  # flink worker and head node configuration
  flink_cluster_name                  = var.flink_cluster_name
  flink_version                       = var.flink_version
  flink_head_node_count               = var.flink_head_node_count
  flink_head_node_sku                 = var.flink_head_node_sku
  flink_worker_node_count             = var.flink_worker_node_count
  flink_worker_node_sku               = var.flink_worker_node_sku
  flink_secure_shell_node_count       = var.flink_secure_shell_node_count
  # flink configuration
  history_server_conf                 = var.history_server_conf
  job_manager_conf                    = var.job_manager_conf
  task_manager_conf                   = var.task_manager_conf
  tags                                = local.tags
  # log analytics
  la_workspace_id                     = module.hdi_on_aks_pool.log_analytics_workspace_id
  use_log_analytics_for_flink         = var.use_log_analytics_for_flink
  # sql server and hive enabled details, if name is empty that means no sql server is defined
  flink_hive_db                       = var.flink_hive_db
  flink_hive_enabled_flag             = var.flink_hive_enabled_flag
  sql_server_id                       = var.sql_server_name!="" ? module.cluster_init.sql_server_id : ""
  sql_server_admin_user_name          = var.sql_server_admin_user_name
  sql_server_name                     = module.cluster_init.sql_server_name
  # key vault for SQL server secret
  kv_id                               = var.key_vault_name !="" ? module.cluster_init.kv_id : ""
  kv_sql_server_secret_name           = var.kv_sql_server_secret_name
  # auto scale
  flink_auto_scale_flag               = var.flink_auto_scale_flag
  flink_auto_scale_type               = var.flink_auto_scale_type
  flink_graceful_decommission_timeout = var.flink_graceful_decommission_timeout
  depends_on                          = [module.cluster_init]
}

module "spark_cluster" {
  source                                         = "./modules/spark"
  env                                            = var.env
  cluster_version                                = var.cluster_version
  hdi_arm_api_version                            = var.hdi_arm_api_version
  create_spark_cluster_flag                      = var.create_spark_cluster_flag
  hdi_on_aks_pool_id                             = module.hdi_on_aks_pool.pool_id
  # Key Vault
  kv_id                                          = var.key_vault_name !="" ? module.cluster_init.kv_id : ""
  kv_sql_server_secret_name                      = var.kv_sql_server_secret_name
  # Log Analytics
  la_workspace_id                                = module.hdi_on_aks_pool.log_analytics_workspace_id
  use_log_analytics_for_spark                    = var.use_log_analytics_for_spark
  location_name                                  = var.location_name
  # Auto scale
  spark_auto_scale_flag                          = var.spark_auto_scale_flag
  spark_auto_scale_type                          = var.spark_auto_scale_type
  spark_cooldown_period_for_load_based_autoscale = var.spark_cooldown_period_for_load_based_autoscale
  spark_graceful_decommission_timeout            = var.spark_graceful_decommission_timeout
  spark_max_load_based_auto_scale_worker_nodes   = var.spark_max_load_based_auto_scale_worker_nodes
  # spark related
  spark_cluster_name                             = var.spark_cluster_name
  spark_head_node_count                          = var.spark_head_node_count
  spark_head_node_sku                            = var.spark_head_node_sku
  spark_secure_shell_node_count                  = var.spark_secure_shell_node_count
  spark_version                                  = var.spark_version
  spark_worker_node_count                        = var.spark_worker_node_count
  # sql server detail and hive metastore
  spark_hive_db                                  = var.spark_hive_db
  spark_hive_enabled_flag                        = var.spark_hive_enabled_flag
  sql_server_admin_user_name                     = var.sql_server_admin_user_name
  sql_server_id                                  = var.sql_server_name!="" ? module.cluster_init.sql_server_id : ""
  sql_server_name                                = module.cluster_init.sql_server_name
  # storage account and container
  storage_account_name                           = module.cluster_init.storage_name
  storage_account_primary_dfs_host               = module.cluster_init.storage_dfs_host
  spark_cluster_default_container                = var.spark_cluster_default_container
  # MSI related
  user_managed_client_id                         = module.cluster_init.msi_client_id
  user_managed_principal_id                      = module.cluster_init.msi_principal_id
  user_managed_resource_id                       = module.cluster_init.msi_resource_id
  tags                                           = local.tags
  depends_on                                     = [module.cluster_init]
}

module "trino_cluster" {
  source                              = "./modules/trino"
  cluster_version                     = var.cluster_version
  create_trino_cluster_flag           = var.create_trino_cluster_flag
  env                                 = var.env
  hdi_on_aks_pool_id                  = module.hdi_on_aks_pool.pool_id
  hdi_arm_api_version                 = var.hdi_arm_api_version
  # Key Vault
  kv_id                               = var.key_vault_name !="" ? module.cluster_init.kv_id : ""
  kv_sql_server_secret_name           = var.kv_sql_server_secret_name
  # Log Analytics
  la_workspace_id                     = module.hdi_on_aks_pool.log_analytics_workspace_id
  use_log_analytics_for_trino         = false
  location_name                       = var.location_name
  # SQL Server
  sql_server_admin_user_name          = var.sql_server_admin_user_name
  sql_server_id                       = var.sql_server_name!="" ? module.cluster_init.sql_server_id : ""
  sql_server_name                     = module.cluster_init.sql_server_name
  # hive catalog related
  trino_hive_catalog_name             = var.trino_hive_catalog_name
  trino_hive_db                       = var.trino_hive_db
  trino_hive_enabled_flag             = var.trino_hive_enabled_flag
  # storage account and container
  storage_account_name                = module.cluster_init.storage_name
  trino_cluster_default_container     = var.trino_cluster_default_container
  storage_account_primary_dfs_host    = module.cluster_init.storage_dfs_host
  # for auto scale
  trino_auto_scale_flag               = var.trino_auto_scale_flag
  trino_auto_scale_type               = var.trino_auto_scale_type
  # cluster related information
  trino_cluster_name                  = var.trino_cluster_name
  trino_head_node_count               = var.trino_head_node_count
  trino_head_node_sku                 = var.trino_head_node_sku
  trino_worker_node_count             = var.trino_worker_node_count
  trino_worker_node_sku               = var.trino_worker_node_sku
  trino_secure_shell_node_count       = var.trino_secure_shell_node_count
  trino_version                       = var.trino_version
  trino_graceful_decommission_timeout = var.trino_graceful_decommission_timeout
  # MSI related
  user_managed_client_id              = module.cluster_init.msi_client_id
  user_managed_principal_id           = module.cluster_init.msi_principal_id
  user_managed_resource_id            = module.cluster_init.msi_resource_id
  tags                                = local.tags
  depends_on                          = [module.cluster_init]
}

module "flink_job_submission" {
  source                     = "./modules/flink-job"
  count                      = var.create_flink_cluster_flag && var.flink_job_action_flag ? 1 : 0
  env                        = var.env
  flink_job_action_flag      = var.flink_job_action_flag
  hdi_arm_api_version        = var.hdi_arm_api_version
  flink_cluster_id           = module.flink_cluster.flink_cluster_id
  hdi_on_aks_pool_id         = module.hdi_on_aks_pool.pool_id
  location_name              = var.location_name
  # job related information
  storage_account_name       = module.cluster_init.storage_name
  flink_jar_container        = var.flink_cluster_default_container
  flink_job_args             = var.flink_job_args
  flink_job_entry_class_name = var.flink_job_entry_class_name
  flink_job_jar_file         = var.flink_job_jar_file
  flink_job_name             = var.flink_job_name
  flink_job_action           = var.flink_job_action
  tags                       = local.tags
  depends_on                 = [module.flink_cluster, module.cluster_init]
}