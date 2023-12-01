terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

# create HDInsight on AKS pool, It will use managed_resource_group_name and subnet if they are defined
resource "azapi_resource" "hdi_aks_cluster_pool" {
  type                      = "Microsoft.HDInsight/clusterpools@2023-06-01-preview"
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
