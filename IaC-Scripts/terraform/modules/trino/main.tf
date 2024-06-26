terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

data "azurerm_client_config" "current" {}


locals {
  # when it is indicated that use log analytics for Trino Cluster
  # and Log Analytics is created earlier then mark log analytics enabled
  la_flag         = (var.use_log_analytics_for_trino && length(var.la_workspace_id)>0) ? true : false
  catalog_profile = (var.trino_hive_enabled_flag && length(var.sql_server_name)>0 && length(var.trino_hive_catalog_name)>0) ? true : false
}

# create trino cluster container
resource "azurerm_storage_container" "trino_cluster_container" {
  count                 = var.create_trino_cluster_flag ? 1 : 0
  name                  = var.trino_cluster_default_container
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}

# create Hive database only when sql server is defined and hive is enabled
resource "azurerm_mssql_database" "trino_hive_db" {
  count     = (var.create_trino_cluster_flag && local.catalog_profile) ? 1 : 0
  name      = var.trino_hive_db
  server_id = var.sql_server_id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  tags      = var.tags
}

resource "azapi_resource" "hdi_aks_cluster_trino" {
  count                     = var.create_trino_cluster_flag ? 1 : 0
  type                      = "Microsoft.HDInsight/clusterpools/clusters@${var.hdi_arm_api_version}"
  name                      = var.trino_cluster_name
  parent_id                 = var.hdi_on_aks_pool_id
  location                  = var.location_name
  schema_validation_enabled = false
  tags                      = var.tags

  body = jsonencode({
    properties = {
      clusterType    = "trino",
      computeProfile = {
        nodes = [
          {
            type   = "head",
            vmSize = var.trino_head_node_sku,
            count  = var.trino_head_node_count
          },
          {
            type   = "worker",
            vmSize = var.trino_worker_node_sku,
            count  = var.trino_worker_node_count
          }
        ]
      },
      clusterProfile = {
        clusterVersion  = var.cluster_version,
        ossVersion      = var.trino_version,
        identityProfile = {
          msiResourceId = var.user_managed_resource_id
          msiClientId   = var.user_managed_client_id
          msiObjectId   = var.user_managed_principal_id
        },
        clusterAccessProfile = {
          enableInternalIngress = var.trino_enable_private_cluster
        }
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
        serviceConfigsProfiles = (local.catalog_profile) ? [
          # use only when Hive Catalog is enabled
          {
            serviceName = "trino",
            configs     = [
              {
                component = "common",
                files     = [
                  {
                    fileName = "config.properties",
                    values   = {
                      "hive.metastore.hdi.metastoreDbConnectionURL"            = "jdbc:sqlserver://${var.sql_server_name}.database.windows.net;database=${azurerm_mssql_database.trino_hive_db[0].name};encrypt=true;trustServerCertificate=true;create=false;loginTimeout=30",
                      "hive.metastore.hdi.metastoreDbConnectionUserName"       = var.sql_server_admin_user_name,
                      "hive.metastore.hdi.metastoreDbConnectionPasswordSecret" = var.kv_sql_server_secret_name,
                      "hive.metastore.hdi.metastoreWarehouseDir"               = "abfs://${azurerm_storage_container.trino_cluster_container[0].name}@${var.storage_account_primary_dfs_host}/hive/warehouse"
                    }
                  }
                ]
              },
              {
                component = "catalogs",
                files     = [
                  {
                    fileName = "${var.trino_hive_catalog_name}.properties"
                    values   = {
                      "connector.name"        = "hive",
                      "hive.allow-drop-table" = "true",
                      "hive.metastore"        = "hdi"
                    }
                  }
                ]
              }
            ]
          }
        ] : null,
        sshProfile = {
          count     = var.trino_secure_shell_node_count,
          podPrefix = "pod"
        },
        autoscaleProfile = (var.trino_auto_scale_flag) ? {
          enabled                     = var.trino_auto_scale_flag,
          autoscaleType               = var.trino_auto_scale_type,
          gracefulDecommissionTimeout = var.trino_graceful_decommission_timeout,
          scheduleBasedConfig         = {
            schedules    = jsondecode(file("${path.cwd}/conf/env/${var.env}/cluster_conf/trino/trino_schedulebased_auto_scale_config.json")),
            timeZone     = "UTC",
            defaultCount = var.trino_worker_node_count
          }
        } : null,
        trinoProfile        = {},
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
    azurerm_storage_container.trino_cluster_container,
    azurerm_mssql_database.trino_hive_db
  ]
  response_export_values = ["*"]
}
