# cluster name is not prefixed and suffixed
create_flink_cluster_flag       = true
flink_version                   = "1.16.0"
flink_cluster_name              = "demoflink"
flink_head_node_count           = 2
flink_head_node_sku             = "Standard_D8ds_v5"
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
flink_hive_enabled_flag = true
flink_hive_db           = "terraform_hive_db"
# enable auto scale for the Flink cluster, if yes specify auto scale configuration from flink_ScheduleBased_auto_scale_config.json
# use schedule based only here, load based is not support
flink_auto_scale_type   = "ScheduleBased"
flink_auto_scale_flag   = true