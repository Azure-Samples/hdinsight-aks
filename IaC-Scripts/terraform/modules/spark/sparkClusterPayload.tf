# payload construction, the Load based and schedule based has different payload for autoscaleProfile
# and terraform expect that if/else should match the return type, to avoid such error it is modularized by each profile
locals {
  // worker and head node information
  computer_profile = jsonencode({
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
  })

  // ssh related information
  ssh_profile = jsonencode({
    count     = var.spark_secure_shell_node_count,
    podPrefix = "pod"
  })

  // schedule based autoscale
  schedule_based_autoscale_profile = jsonencode(var.spark_auto_scale_flag ? ({
    enabled                     = var.spark_auto_scale_flag,
    autoscaleType               = var.spark_auto_scale_type,
    gracefulDecommissionTimeout = var.spark_graceful_decommission_timeout,
    scheduleBasedConfig         = {
      schedules    = jsondecode(file("${path.cwd}/conf/env/${var.env}/cluster_conf/spark/spark_LoadBased_autoscale_config.json")),
      timeZone     = "UTC",
      defaultCount = var.spark_worker_node_count
    }
  }) : null)

  // load based autoscale
  load_based_autoscale_profile = jsonencode(var.spark_auto_scale_flag ? ({
    enabled                     = var.spark_auto_scale_flag,
    autoscaleType               = var.spark_auto_scale_type,
    gracefulDecommissionTimeout = var.spark_graceful_decommission_timeout,
    loadBasedConfig             = {
      minNodes       = var.spark_worker_node_count,
      maxNodes       = var.spark_max_load_based_auto_scale_worker_nodes,
      pollInterval   = 300,
      cooldownPeriod = var.spark_cooldown_period_for_load_based_autoscale,
      scalingRules   = jsondecode(file("${path.cwd}/conf/env/${var.env}/cluster_conf/spark/spark_ScheduleBased_auto_scale_config.json"))
    }
  }) : null)

  // identity and authorization
  identity_profile = jsonencode({
    msiResourceId = var.user_managed_resource_id
    msiClientId   = var.user_managed_client_id
    msiObjectId   = var.user_managed_principal_id
  })

  authorization_profile = {
    userIds = [data.azurerm_client_config.current.object_id]
  }

  // key vault secret information
  secret_profile = jsonencode((local.metastore_enabled) ? {
    keyVaultResourceId = var.kv_id,
    secrets            = [
      {
        referenceName      = var.kv_sql_server_secret_name,
        type               = "Secret",
        keyVaultObjectName = var.kv_sql_server_secret_name,
      }
    ]
  } : null)

  // spark related information
  spark_profile = jsonencode(merge(
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
  ))

  log_analytics_profile = jsonencode({
    enabled         = local.la_flag,
    applicationLogs = {
      stdErrorEnabled = local.la_flag,
      stdOutEnabled   = local.la_flag
    },
    metricsEnabled = local.la_flag
  })

  schedule_based_autoscale_payload = jsonencode({
    properties = {
      clusterType    = "spark",
      computeProfile = local.computer_profile,
      clusterProfile = {
        clusterVersion         = var.cluster_version,
        ossVersion             = var.spark_version,
        identityProfile        = local.identity_profile,
        authorizationProfile   = local.authorization_profile,
        # add key vault if you are using Hive enabled
        secretsProfile         = local.secret_profile,
        serviceConfigsProfiles = [],
        sshProfile             = local.ssh_profile,
        autoscaleProfile       = local.schedule_based_autoscale_profile,
        sparkProfile           = local.spark_profile
        logAnalyticsProfile    = local.log_analytics_profile
      } # cluster profile
    }
  } ) # jsonencode ends

  load_based_autoscale_payload = jsonencode({
    properties = {
      clusterType    = "spark",
      computeProfile = local.computer_profile,
      clusterProfile = {
        clusterVersion         = var.cluster_version,
        ossVersion             = var.spark_version,
        identityProfile        = local.identity_profile,
        authorizationProfile   = local.authorization_profile,
        # add key vault if you are using Hive enabled
        secretsProfile         = local.secret_profile
        serviceConfigsProfiles = [],
        sshProfile             = local.ssh_profile,
        autoscaleProfile       = local.load_based_autoscale_profile,
        sparkProfile           = local.spark_profile,
        logAnalyticsProfile    = local.log_analytics_profile
      } # cluster profile
    }
  } ) # jsonencode ends

  payload = var.spark_auto_scale_type=="ScheduleBased" ? local.schedule_based_autoscale_payload : local.load_based_autoscale_payload
}
