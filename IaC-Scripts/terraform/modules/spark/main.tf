terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

data "azurerm_client_config" "current" {}


locals {
  # when it is indicated that use log analytics for Spark Cluster
  # and Log Analytics is created earlier then mark log analytics enabled
  la_flag           = (var.use_log_analytics_for_spark && var.la_workspace_id!="") ? true : false
  metastore_enabled = (var.spark_hive_enabled_flag && var.sql_server_name!="") ? true : false
  payload           = var.spark_auto_scale_type=="ScheduleBased" ? local.schedule_based_autoscale_payload : local.load_based_autoscale_payload
}

# create spark cluster container
resource "azurerm_storage_container" "spark_cluster_container" {
  count                 = var.create_spark_cluster_flag ? 1 : 0
  name                  = var.spark_cluster_default_container
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}

# create Hive database only when sql server is defined and hive is enabled
resource "azurerm_mssql_database" "spark_hive_db" {
  count     = local.metastore_enabled ? 1 : 0
  name      = var.spark_hive_db
  server_id = var.sql_server_id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  tags      = var.tags
}

resource "azapi_resource" "hdi_aks_cluster_spark" {
  count                     = var.create_spark_cluster_flag ? 1 : 0
  type                      = "Microsoft.HDInsight/clusterpools/clusters@2023-06-01-preview"
  name                      = var.spark_cluster_name
  parent_id                 = var.hdi_on_aks_pool_id
  location                  = var.location_name
  schema_validation_enabled = false
  tags                      = var.tags

  body       = local.payload
  depends_on = [
    azurerm_storage_container.spark_cluster_container,
    azurerm_mssql_database.spark_hive_db
  ]
  response_export_values = ["*"]
}
