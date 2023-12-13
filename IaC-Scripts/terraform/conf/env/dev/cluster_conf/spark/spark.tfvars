# cluster name is not prefixed and suffixed
create_spark_cluster_flag                        = true
spark_version                                    = "3.3.1"
spark_cluster_name                               = "demospark"
# minimum we need 3 head nodes
spark_head_node_count                            = 3
spark_head_node_sku                              = "Standard_D8ds_v5"
spark_worker_node_count                          = 3
spark_worker_node_sku                            = "Standard_D8ds_v5"
spark_cluster_default_container                  = "sparkcluster"
spark_secure_shell_node_count                    = 1
# if hive is enabled, please ensure you supply sql_server_name part if cluster.tfvars
# it is assumed that we need to create new hive database
spark_hive_enabled_flag                          = true
spark_hive_db                                    = "terraform_hive_db"
# enable auto scale for the spark cluster, if yes specify auto scale configuration from spark_ScheduleBased_auto_scale_config.json
spark_auto_scale_type                            = "LoadBased"
spark_auto_scale_flag                            = true
# auto scale configuration
# This is the maximum time to wait for running containers and applications to complete before
# transitioning a DECOMMISSIONING node to DECOMMISSIONED. The default value is 60 sec.
spark_graceful_decommission_timeout              = 60
# these are require only for load based auto scale
# After an auto scaling event occurs, the amount of time to wait before enforcing another scaling policy. The default value is 180 sec.
spark_cooldown_period_for_load_based_autoscale = 180
# spark minimum worker nodes for load based auto scale is spark_worker_node_count
spark_max_load_based_auto_scale_worker_nodes     = 5