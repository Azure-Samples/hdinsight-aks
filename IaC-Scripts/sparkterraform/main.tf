data "azurerm_client_config" "current" {}

# create resource group
resource "azurerm_resource_group" "pool_resource_group" {
  name     = var.rg_name
  location = var.location_name
  tags     = local.tags
}

# create VNet
resource "azurerm_virtual_network" "hdi_vnet" {
  name                = var.vnet_name
  location            = var.location_name
  resource_group_name = azurerm_resource_group.pool_resource_group.name
  address_space       = ["10.0.0.0/22"]
  tags                = local.tags
  depends_on          = [azurerm_resource_group.pool_resource_group]
}

# Create Subnet
resource "azurerm_subnet" "hdi_default_subnet_default" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.pool_resource_group.name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.0.0/22"]
  service_endpoints    = ["Microsoft.Storage"]
  depends_on           = [azurerm_virtual_network.hdi_vnet]
}

# create HDInsight on AKS pool
resource "azapi_resource" "hdi_aks_cluster_pool" {
  type                      = "Microsoft.HDInsight/clusterpools@${var.hdi_arm_api_version}"
  name                      = var.hdi_on_aks_pool_name
  parent_id                 = azurerm_resource_group.pool_resource_group.id
  location                  = var.location_name
  schema_validation_enabled = false
  tags                      = local.tags

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
      {
        networkProfile = {
          subnetId = azurerm_subnet.hdi_default_subnet_default.id
        }
      }
    )
  })
  response_export_values = ["*"]
}

# Create storage account
resource "azurerm_storage_account" "hdi_storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.pool_resource_group.name
  location                 = var.location_name
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.tags
  depends_on               = [azapi_resource.hdi_aks_cluster_pool]
}

# create spark cluster container
resource "azurerm_storage_container" "spark_cluster_container" {
  name                  = var.spark_cluster_default_container
  storage_account_name  = azurerm_storage_account.hdi_storage_account.name
  container_access_type = "private"
  depends_on            = [
    azurerm_storage_account.hdi_storage_account
  ]
}

# assign Contributor role to the current client config
resource "azurerm_role_assignment" "hdi_storage_contributor_role" {
  scope                = azurerm_storage_account.hdi_storage_account.id
  for_each             = {for idx, value in toset(var.current_client_storage_permission) : idx=>value}
  role_definition_name = each.value
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_storage_account.hdi_storage_account]
}

resource "azurerm_user_assigned_identity" "hdi_msi_id" {
  location            = var.location_name
  name                = var.user_assigned_identity_name
  resource_group_name = var.rg_name
  tags                = local.tags
  depends_on          = [azapi_resource.hdi_aks_cluster_pool]
}

# Assign Storage Blob Data Owner role for User Managed Identity on storage account
resource "azurerm_role_assignment" "hdi_st_role_identity" {
  scope                = azurerm_storage_account.hdi_storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.hdi_msi_id.principal_id
  depends_on           = [
    azurerm_user_assigned_identity.hdi_msi_id,
    azurerm_storage_account.hdi_storage_account
  ]
}

# create spark cluster
resource "azapi_resource" "hdi_aks_cluster_spark" {
  type                      = "Microsoft.HDInsight/clusterpools/clusters@${var.hdi_arm_api_version}"
  name                      = var.spark_cluster_name
  parent_id                 = azapi_resource.hdi_aks_cluster_pool.id
  location                  = var.location_name
  schema_validation_enabled = false
  tags                      = local.tags

  body       = var.spark_auto_scale_type=="ScheduleBased" ? local.schedule_based_autoscale_payload : local.load_based_autoscale_payload
  depends_on = [
    azurerm_storage_container.spark_cluster_container,
    azapi_resource.hdi_aks_cluster_pool,
    azurerm_user_assigned_identity.hdi_msi_id
  ]
  response_export_values = ["*"]
}
