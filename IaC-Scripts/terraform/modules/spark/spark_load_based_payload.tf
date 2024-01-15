# payload to create load based auto scale
locals {
  # final payload for load based autoscale
  load_based_autoscale_payload = (var.create_spark_cluster_flag) ? jsonencode({
    properties = {
      clusterType    = "spark",
      computeProfile = {
        nodes = [
          {
            type   = "head",
            vmSize = var.spark_head_node_sku,
            count  = var.spark_head_node_count
          },
          {
            type   = "worker",
            vmSize = var.spark_worker_node_sku,
            count  = var.spark_worker_node_count
          }
        ]
      },
      clusterProfile = {
        clusterVersion  = var.cluster_version,
        ossVersion      = var.spark_version,
        identityProfile = {
          msiResourceId = var.user_managed_resource_id
          msiClientId   = var.user_managed_client_id
          msiObjectId   = var.user_managed_principal_id
        },
        authorizationProfile = {
          userIds = [data.azurerm_client_config.current.object_id]
        },
        # add key vault if you are using Hive enabled
        secretsProfile = local.metastore_enabled ? {
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
          count     = var.spark_secure_shell_node_count,
          podPrefix = "pod"
        },
        autoscaleProfile = var.spark_auto_scale_flag ? {
          enabled                     = var.spark_auto_scale_flag,
          autoscaleType               = var.spark_auto_scale_type,
          gracefulDecommissionTimeout = var.spark_graceful_decommission_timeout,
          loadBasedConfig             = {
            minNodes       = var.spark_worker_node_count,
            maxNodes       = var.spark_max_load_based_auto_scale_worker_nodes,
            pollInterval   = 300,
            cooldownPeriod = var.spark_cooldown_period_for_load_based_autoscale,
            scalingRules   = jsondecode(file("${path.cwd}/conf/env/${var.env}/cluster_conf/spark/spark_loadbased_autoscale_config.json"))
          }
        } : null,
        sparkProfile = merge(
          {
            defaultStorageUrl = "abfs://${azurerm_storage_container.spark_cluster_container[0].name}@${var.storage_account_primary_dfs_host}"
          },
          coalesce(local.metastore_enabled ?
          {
            metastoreSpec = {
              dbServerHost         = "${var.sql_server_name}.database.windows.net",
              dbName               = azurerm_mssql_database.spark_hive_db[0].name,
              dbUserName           = var.sql_server_admin_user_name,
              keyVaultId           = var.kv_id,
              dbPasswordSecretName = var.kv_sql_server_secret_name
            }
          }
          : {}
          )# coalesce ends
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
  }) : ""
}