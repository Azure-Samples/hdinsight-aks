output "flink_cluster_dns" {
  value = var.create_spark_cluster_flag ? jsondecode(azapi_resource.hdi_aks_cluster_spark[0].output).properties.clusterProfile.connectivityProfile.web.fqdn : ""
}