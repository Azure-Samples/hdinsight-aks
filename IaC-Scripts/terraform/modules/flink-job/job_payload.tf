locals {

  new_update_job_flag = (var.flink_job_action=="NEW" || var.flink_job_action=="UPDATE")

  # for delete, cancel, and stop action needs only jobType, jobName and action
  payload = jsonencode({
    properties = merge(
      {
        jobType = "FlinkJob"
      },
      {
        jobName = var.flink_job_name
      },
      {
        action = var.flink_job_action
      },
      coalesce(local.new_update_job_flag ? {
        jobJarDirectory = "abfs://${azurerm_storage_blob.flink_job_jar_upload[0].storage_container_name}@${var.storage_account_name}.dfs.core.windows.net"
      } : {}),
      coalesce(local.new_update_job_flag ? {
        jarName = azurerm_storage_blob.flink_job_jar_upload[0].name
      } : {}),
      coalesce(local.new_update_job_flag ? {
        entryClass = var.flink_job_entry_class_name
      } : {}),
      coalesce(local.new_update_job_flag ? {
        args = var.flink_job_args
      } : {}),
      coalesce(local.new_update_job_flag ? {
        flinkConfiguration = jsondecode(file("${path.cwd}/conf/env/${var.env}/job_conf/flink/flink_job_conf.json"))
      } : {}),
    )// merge ends
  }) # jsonencode ends
}