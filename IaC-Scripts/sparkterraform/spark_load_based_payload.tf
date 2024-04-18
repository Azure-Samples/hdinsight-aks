# payload to create load based auto scale
locals {
  # final payload for load based autoscale
  load_based_autoscale_payload = jsonencode({
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
          msiResourceId = azurerm_user_assigned_identity.hdi_msi_id.id
          msiClientId   = azurerm_user_assigned_identity.hdi_msi_id.client_id
          msiObjectId   = azurerm_user_assigned_identity.hdi_msi_id.principal_id
        },
        authorizationProfile = {
          userIds = [data.azurerm_client_config.current.object_id]
        },
        # add key vault if you are using Hive enabled
        secretsProfile         = null,
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
            scalingRules   = jsondecode(file("${path.cwd}/conf/spark_loadbased_autoscale_config.json"))
          }
        } : null,
        sparkProfile = {
          defaultStorageUrl = "abfs://${azurerm_storage_container.spark_cluster_container.name}@${azurerm_storage_account.hdi_storage_account.primary_dfs_host}"
        }
      } # cluster profile
    }
  })
}