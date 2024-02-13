# payload to create schedule based auto scale
locals {
  schedule_based_autoscale_payload = (var.spark_auto_scale_type=="ScheduleBased") ? jsonencode({
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
        serviceConfigsProfiles = [],
        sshProfile             = {
          count     = var.spark_secure_shell_node_count,
          podPrefix = "pod"
        },
        autoscaleProfile = (var.spark_auto_scale_flag ? {
          enabled                     = var.spark_auto_scale_flag,
          autoscaleType               = var.spark_auto_scale_type,
          gracefulDecommissionTimeout = var.spark_graceful_decommission_timeout,
          scheduleBasedConfig         = {
            schedules    = jsondecode(file("${path.cwd}/conf/spark_schedulebased_auto_scale_config.json")),
            timeZone     = "UTC",
            defaultCount = var.spark_worker_node_count
          }
        } : null),
        sparkProfile = {
          defaultStorageUrl = "abfs://${azurerm_storage_container.spark_cluster_container.name}@${azurerm_storage_account.hdi_storage_account.primary_dfs_host}"
        }
      } # cluster profile
    }
  }) : ""
}