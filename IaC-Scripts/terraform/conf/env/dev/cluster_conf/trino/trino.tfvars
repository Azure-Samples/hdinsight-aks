# cluster name is not prefixed and suffixed
create_trino_cluster_flag           = true
trino_version                       = "0.426.0"
trino_cluster_name                  = "demotrino"
trino_head_node_count               = 2
trino_head_node_sku                 = "Standard_D8ds_v5"
trino_worker_node_count             = 3
trino_worker_node_sku               = "Standard_D8ds_v5"
trino_cluster_default_container     = "trinocluster"
trino_enable_private_cluster        = false
trino_secure_shell_node_count       = 1
# if hive is enabled, please ensure you supply sql_server_name part if cluster.tfvars
# The trino would require sql server and trino_hive_catalog_name if we would like to use Hive Catalog
trino_hive_enabled_flag             = true
# trino hive catalog name
trino_hive_catalog_name             = "trino_catalog"
# change the database name if you want to use different hive metastore for trino and spark
trino_hive_db                       = "terraform_hive_db"
# enable auto scale for the trino cluster, if yes specify auto scale configuration from trino_ScheduleBased_auto_scale_config.json
# use schedule based only here, load based is not support
trino_auto_scale_type               = "ScheduleBased"
trino_auto_scale_flag               = true
# applicable only when trino_auto_scale_flag is true
trino_graceful_decommission_timeout = 60