output "trino_cluster_dns" {
  value = var.create_trino_cluster_flag ? jsondecode(azapi_resource.hdi_aks_cluster_trino[0].output).properties.clusterProfile.connectivityProfile.web.fqdn : ""
}