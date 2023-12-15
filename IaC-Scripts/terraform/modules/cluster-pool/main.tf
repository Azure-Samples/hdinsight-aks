terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

module "log_analytics" {
  count                     = var.la_name!="" ? 1 : 0
  source                    = "../log-analytics"
  create_log_analytics_flag = var.create_log_analytics_flag
  la_name                   = var.la_name
  la_retention_in_days      = var.la_retention_in_days
  location_name             = var.location_name
  rg_name                   = var.rg_name
}

# create HDInsight on AKS pool, It will use managed_resource_group_name and subnet if they are defined
resource "azapi_resource" "hdi_aks_cluster_pool" {
  type                      = "Microsoft.HDInsight/clusterpools@${var.hdi_arm_api_version}"
  name                      = var.hdi_on_aks_pool_name
  parent_id                 = var.rg_id
  location                  = var.location_name
  schema_validation_enabled = false
  tags                      = var.tags

  body = jsonencode({
    properties = merge(
      {
        clusterPoolProfile = {
          clusterPoolVersion = var.pool_version
        }
      },
      {
        computeProfile = {
          vmSize = var.pool_node_vm_size
        }
      },
      coalesce(
        var.managed_resource_group_name!="" ?
        {
          managedResourceGroupName = var.managed_resource_group_name
        } :
        {}
      ),
      coalesce(
        var.la_name!="" ?
        {
          logAnalyticsProfile = {
            enabled     = true,
            workspaceId = module.log_analytics[0].log_analytics_id
          }
        } :
        {}
      ),
      coalesce(
        var.subnet_id!="" ?
        {
          networkProfile = {
            subnetId = var.subnet_id
          }
        } :
        {}
      )
    )
  })
  response_export_values = ["*"]
}
