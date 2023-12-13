# Log Analytics variable values
# we need create_log_analytics_flag to check if the given la_name is exist or need to create a new one
# this is require because datasource will throw error if the resource is not exist
create_log_analytics_flag   = true
# create_log_analytics_flag is true of false, having LA Name empty means
# nothing is require (neither create or look from data source)
# Workspace Name can only contain alphabet, number, and '-' character. You can not use '-' as the start and end of the name
la_name                     = ""
la_retention_in_days        = 30
# use LA for Flink Cluster
use_log_analytics_for_flink = true