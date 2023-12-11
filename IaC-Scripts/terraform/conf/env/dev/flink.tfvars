# cluster name is not prefixed and suffixed
create_flink_cluster_flag       = true
flink_cluster_name              = "demoflink"
flink_worker_node_count         = 3
flink_worker_node_sku           = "Standard_D8ds_v5"
flink_cluster_default_container = "flinkcluster"
flink_secure_shell_node_count   = 1
# Flink configuration
job_manager_conf                = {
  cpu    = 4,
  memory = 8000
}
task_manager_conf = {
  cpu    = 4,
  memory = 4000
}
history_server_conf = {
  cpu    = 4,
  memory = 8000
}
# if hive is enabled, please ensure you supply sql_server_name part if cluster.tfvars
# it is assumed that we need to create new hive database
flink_hive_enabled = true
flink_hive_db      = "terraform_hive_db"