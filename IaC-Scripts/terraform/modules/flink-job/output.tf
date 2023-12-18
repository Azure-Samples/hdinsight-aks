output "flink_job_id" {
  value = var.flink_job_action_flag ? azapi_resource_action.hdi_aks_flink_job_action[0].id : ""
}