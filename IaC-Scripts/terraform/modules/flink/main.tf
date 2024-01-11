terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

data "azurerm_client_config" "current" {}


locals {
  # when it is indicated that use log analytics for Flink Cluster
  # and Log Analytics is created earlier then mark log analytics enabled
  la_flag         = (var.use_log_analytics_for_flink && length(var.la_workspace_id)>0) ? true : false
  catalog_profile = (var.flink_hive_enabled_flag && length(var.sql_server_name)>0) ? true : false
}

# create flink cluster container
resource "azurerm_storage_container" "flink_cluster_container" {
  count                 = var.create_flink_cluster_flag ? 1 : 0
  name                  = var.flink_cluster_default_container
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}


# create Hive database only when sql server is defined and hive is enabled
resource "azurerm_mssql_database" "flink_hive_db" {
  count     = (var.create_flink_cluster_flag && local.catalog_profile) ? 1 : 0
  name      = var.flink_hive_db
  server_id = var.sql_server_id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  tags      = var.tags
}

resource "azapi_resource" "hdi_aks_cluster_flink" {
  count                     = var.create_flink_cluster_flag ? 1 : 0
  type                      = "Microsoft.HDInsight/clusterpools/clusters@${var.hdi_arm_api_version}"
  name                      = var.flink_cluster_name
  parent_id                 = var.hdi_on_aks_pool_id
  location                  = var.location_name
  schema_validation_enabled = false
  tags                      = var.tags

  body = jsonencode({
    properties = {
      clusterType    = "flink",
      computeProfile = {
        nodes = [
          {
            type   = "head",
            vmSize = var.flink_head_node_sku,
            count  = var.flink_head_node_count
          },
          {
            type   = "worker",
            vmSize = var.flink_worker_node_sku,
            count  = var.flink_worker_node_count
          }
        ]
      },
      clusterProfile = {
        clusterVersion  = var.cluster_version,
        ossVersion      = var.flink_version,
        identityProfile = {
          msiResourceId = var.user_managed_resource_id
          msiClientId   = var.user_managed_client_id
          msiObjectId   = var.user_managed_principal_id
        },
        authorizationProfile = {
          userIds = [data.azurerm_client_config.current.object_id]
        },
        # add key vault if you are using Hive enabled
        secretsProfile = (local.catalog_profile) ? {
          keyVaultResourceId = var.kv_id,
          secrets            = [
            {
              referenceName      = var.kv_sql_server_secret_name,
              type               = "Secret",
              keyVaultObjectName = var.kv_sql_server_secret_name,
            }
          ]
        } : null,
        serviceConfigsProfiles = [],
        sshProfile             = {
          count     = var.flink_secure_shell_node_count,
          podPrefix = "pod"
        },
        autoscaleProfile = (var.flink_auto_scale_flag) ? {
          enabled                     = var.flink_auto_scale_flag,
          autoscaleType               = var.flink_auto_scale_type,
          gracefulDecommissionTimeout = var.flink_graceful_decommission_timeout,
          scheduleBasedConfig         = {
            schedules    = jsondecode(file("${path.cwd}/conf/env/${var.env}/cluster_conf/flink/flink_schedulebased_auto_scale_config.json")),
            timeZone     = "UTC",
            defaultCount = var.flink_worker_node_count
          }
        } : null,
        flinkProfile = merge(
          {
            jobManager = {
              cpu    = tonumber(var.job_manager_conf["cpu"])
              memory = tonumber(var.job_manager_conf["memory"])
            }
          },
          {
            taskManager = {
              cpu    = tonumber(var.task_manager_conf["cpu"])
              memory = tonumber(var.task_manager_conf["memory"])
            }
          },
          {
            historyServer = {
              cpu    = tonumber(var.history_server_conf["cpu"])
              memory = tonumber(var.history_server_conf["memory"])
            }
          },
          {
            storage = {
              storageUri = "abfs://${azurerm_storage_container.flink_cluster_container[0].name}@${var.storage_account_primary_dfs_host}"
            }
          },
          coalesce(local.catalog_profile ?
          {
            catalogOptions = {
              hive = {
                metastoreDbConnectionURL            = "jdbc:sqlserver://${var.sql_server_name}.database.windows.net;database=${azurerm_mssql_database.flink_hive_db[0].name};encrypt=true;trustServerCertificate=true;create=false;loginTimeout=30",
                metastoreDbConnectionUserName       = var.sql_server_admin_user_name,
                metastoreDbConnectionPasswordSecret = var.kv_sql_server_secret_name
              }
            }
          }
          : {}
          )
        ),
        logAnalyticsProfile = {
          enabled         = local.la_flag,
          applicationLogs = {
            stdErrorEnabled = local.la_flag,
            stdOutEnabled   = local.la_flag
          },
          metricsEnabled = local.la_flag
        }
      } # cluster profile
    }
  } ) # jsonencode ends
  depends_on = [
    azurerm_storage_container.flink_cluster_container,
    azurerm_mssql_database.flink_hive_db
  ]
  response_export_values = ["*"]
}
