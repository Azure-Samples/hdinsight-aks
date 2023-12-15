terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

# It assumes that container is already exist in the given storage account
resource "azurerm_storage_blob" "flink_job_jar_upload" {
  count                  = (var.flink_job_action_flag && var.flink_job_name!="") ? 1 : 0
  name                   = var.flink_job_jar_file
  storage_account_name   = var.storage_account_name
  storage_container_name = var.flink_jar_container
  type                   = "Block"
  source                 = var.flink_job_jar_file
}

resource "azapi_resource_action" "hdi_aks_flink_job_action" {
  count                  = (var.flink_job_action_flag && var.flink_job_name!="") ? 1 : 0
  resource_id            = var.flink_cluster_id
  type                   = "Microsoft.HDInsight/clusterpools/clusters@${var.hdi_arm_api_version}"
  action                 = "runJob"
  body                   = local.payload
  response_export_values = ["*"]
  depends_on             = [azurerm_storage_blob.flink_job_jar_upload]
}