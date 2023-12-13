output "flink_cluster_dns" {
  value = var.create_flink_cluster_flag ? jsondecode(azapi_resource.hdi_aks_cluster_flink[0].output).properties.clusterProfile.connectivityProfile.web.fqdn : ""
}