# HDInsight on AKS - Terraform Scripts

These terraform scripts will let you manage your HDInsight on AKS infrastructure using code. There are few common Terraform variables used across multiple modules; those are:

- `location_name` -  Region name for your resources
- `env` - Environment name - User can set this variable value via tfvars or `-var env=dev`. This variable is used for to pick right tfvars and [configurations files](./terraform/conf/env/)

## Modules

The codebase has following modules:

### [Resoure Group](./terraform/modules/resource-group/main.tf)

Creates a resource group to hold customer managed resources related to HDInsight on AKS. The module will create the resource group only when `create_rg_for_pool_flag=true`, in the case of `create_rg_for_pool_flag=false`, It will use terraform data source to get information defined outside of Terraform with given resource group name. The resource group name will be prefixed and suffixed by `prefix` and `suffix` variables. Terraform variable definitions for resource groups are defined in [pool.tfvars](./terraform/conf/env/dev/pool.tfvars).

### [Network](./terraform/modules/network/main.tf) 

HDInsight on AKS allows you to bring your own VNet and Subnet, enabling you to customize your network requirements to suit the needs of your enterprise. You can use your existing VNet and Subnet or create a new one with following set of variables: `vnet_name`,`create_vnet_flag`,`subnet_name`, and `create_subnet_flag`. Terraform variable definitions for networking are defined in [pool.tfvars](./terraform/conf/env/dev/pool.tfvars).

| vnet_name  |create_vnet_flag|subnet_name|create_subnet_flag|Action                      |
|------------|----------------|-----------|------------------|----------------------------|
|not empty   |            true|not empty  |              true|create a new Vnet and Subnet in given pool resource group name|
|not empty   |            true|not empty  |             false|create a new Vnet and use existing Subnet in given pool resource group name|
|not empty   |           false|not empty  |             false|use existing Vnet and Subnet from `vnet_rg_name`|
|not empty   |           false|not empty  |              true|use existing Vnet and create a new Subnet from `vnet_rg_name`|
|empty       |              NA|NA         |                NA|No VNet and SubNet|
|not empty   |           false|empty      |                NA|No VNet and SubNet|

### [Log Analytics](./terraform/modules/log-analytics/main.tf)

Log Analytics workspace is optional and needs to be created ahead in case you would like to use Azure Monitor capabilities like Azure Log Analytics. You can use your existing Log Analytics Workspace or create a new one with following set of variables:`create_log_analytics_flag`, and `la_name`. Terraform variable definitions for Log analytics for the HDInsight on AKS pool and clusters are defined in [la.tfvars](./terraform/conf/env/dev/la.tfvars).

| create_log_analytics_flag  |la_name  |Action                      |
|----------------------------|-------  |----------------------------|
|true                        |non empty|create a Log Analytics workspace|
|false                       |non empty|use existing Log Analytics workspace|
|NA                          |empty    |don't use any Log Analytics workspace|

### [Cluster-pool](./terraform/modules/cluster-pool/main.tf)

Cluster pools for HDInsight on AKS are a logical grouping of clusters and support a set of clusters in the same pool, which helps in building robust interoperability across multiple cluster types. It can be created within an existing virtual network or outside a virtual network (as described on Network module). A cluster pool in HDInsight on AKS corresponds to one cluster in AKS infrastructure.

The cluster pool creation creates a Managed resource group; It holds ancillary resources created by HDInsight on AKS. By default, two managed resource groups are created with cluster pool creation.
   - RG1 = <Default name {hdi-deploymentId of cluster pool}> - To hold ancillary resources for HDInsight on AKS
   - RG2 = <MC_{RG1}_{cluster pool name}_{region}> - To hold infrastructure resources for Azure Kubernetes Services

When you create a pool optionally you can pass RG1 to satisfy your organization’s resource group name policies. The Terraform variable `managed_resource_group_name` let you define custom resource group name for RG1,  if `managed_resource_group_name` is test1 then the complete RG1 name will be `MC_test1_<hdi_on_aks_pool_name>_<location_name>`, you can leave empty string for the `managed_resource_group_name` if you don't want any custom managed resource group. 

### [Cluster-init](./terraform/modules/cluster-init/main.tf) 

The cluster-init module initialize the [cluster prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-resources). Clusters are individual compute workloads, such as Apache Spark, Apache Flink, or Trino, which can be created in the same cluster pool. Some of these prerequisites are:

#### [User Managed Identity](./terraform/modules/identity/main.tf)

It is one of **mandatory resources** for cluster creation. MSI is used as a security standard for authentication and authorization across resources, except SQL Database. The role assignment occurs prior to deployment to authorize MSI to storage and the secrets are stored in Key vault for SQL Database. Storage support is with ADLS Gen2 and is used as data store for the compute engines, and SQL Database is used for table management on Hive Metastore.

Terraform variable definitions for networking are defined in [cluster.tfvars](./terraform/conf/env/dev/cluster.tfvars). The `user_assigned_identity_name` variable is prefixed and suffixed by `prefix` and `suffix` variables.

| user_assigned_identity_name  |create_user_assigned_identity_flag  |Action                      |
|------------------------------|------------------------------------|----------------------------|
|non empty                     |true                                |creates a new MSI           |
|non empty                     |false                               |use existing MSI from given pool resource group name|
|empty                         |NA                                  |error                       |

#### [Storage Account](./terraform/modules/storage/main.tf)

It is one of **mandatory resources** for cluster creation. A Storage account can be shared across multiple clusters, but they should not share container. Required container for each cluster is created within cluster modules. Terraform variable definitions for networking are defined in [cluster.tfvars](./terraform/conf/env/dev/cluster.tfvars). The `storage_name` variable defines the storage account name and  `create_storage_flag` controls creation of the storage account. 


| storage_name                 |create_storage_flag                 |Action                      |
|------------------------------|------------------------------------|----------------------------|
|non empty                     |true                                |creates a new storage account|
|non empty                     |false                               |use existing storage account from given pool resource group name|
|empty                         |NA                                  |error                       |

#### [Key Vault](./terraform/modules/key-vault/main.tf) 

It is an **optional resource**, requires only if you need metastore support for your clusters. The HDInsight on AKS clusters support only Azure SQL Database as inbuilt metastore for Apache Spark, Apache Flink, and Apache Flink. Currently HDInsight on AKS supports SQL Server and uses ["SQL authentication"](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-resources#create-azure-sql-database) authentication method only.

Azure Key Vault allows you to store the SQL Server admin password set during SQL Database creation. HDInsight on AKS platform doesn’t deal with the credential directly. Hence, it's necessary to store your important credentials in the Key Vault.

Terraform variable definitions for Key Vault are defined in [cluster.tfvars](./terraform/conf/env/dev/cluster.tfvars). The `key_vault_name` variable defines the Azure Key Vault name and `create_key_vault_flag` controls creation of the Azure Key Vault. 


| key_vault_name               |create_key_vault_flag               |Action                      |
|------------------------------|------------------------------------|----------------------------|
|non empty                     |true                                |creates a new Key Vault     |
|non empty                     |false                               |use existing Key Vault from given pool resource group name|
|empty                         |NA                                  |No Action                   |


#### [SQL Server](./terraform/modules/sql-database/main.tf)

It is an **optional resource**,  requires only if you need metastore support for your cluster. Create an Azure SQL Database to be used as an external metastore during cluster creation or you can use an existing SQL Database. 
:warning: *Due to Hive limitation, "-" (hyphen) character in metastore database name is not supported.

Terraform variable definitions for Key Vault are defined in [cluster.tfvars](./terraform/conf/env/dev/cluster.tfvars). The `sql_server_name` variable defines the Azure SQL server name and `create_sql_server_flag` controls creation of the Azure SQL Server. 

| sql_server_name              |create_sql_server_flag              |Action                      |
|------------------------------|------------------------------------|----------------------------|
|non empty                     |true                                |creates a new SQL server    |
|non empty                     |false                               |use existing SQL server from given pool resource group name|
|empty                         |NA                                  |No Action                   |

#### [SQL VNet](./terraform/modules/sql-vnet/main.tf)

It manages rules for allowing traffic between an Azure SQL server and a subnet of a virtual network only. It will not create any network and firewall rule in the case of `sql_server_name` or `subnet_name` is empty (that means you don't want to use external metastore and no virtual network).

### [Flink Cluster](./terraform/modules/flink/main.tf)

It [creates an Apache Flink cluster](https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal#create-an-apache-flink-cluster) in a [cluster pool](#cluster-pool). It is dependent on [cluster-init](#cluster-init). 

The current terraform module supports following features for the HDInsight on AKS Apache Flink cluster.
- [Schedule Based Auto Scale](./terraform/conf/env/dev/cluster_conf/flink/flink_schedulebased_auto_scale_config.json)
- Hive Catalog
- Log Analytics
- [Service Configuration](./terraform/conf/env/dev/cluster_conf/flink/flink.tfvars)
  - CPU for Task manager, Job Manager, and History Server
  - Memory for Task manager, Job Manager, and History Server 

:information_source: You can have common or different databases for different workload (Spark, Flink, and Trino). It is managed by `flink_hive_db` variable. It is mandatory to have `sql_server_name` before you can use a hive catalog.

### [Spark Cluster](./terraform/modules/spark/main.tf)

It [creates an Apache Spark cluster](https://learn.microsoft.com/en-us/azure/hdinsight-aks/spark/create-spark-cluster) in a [cluster pool](#cluster-pool), It is dependent on [cluster-init](#cluster-init). 

The current terraform module supports following features for the HDInsight on AKS Apache Flink cluster.
- [Schedule Based Auto Scale](./terraform/conf/env/dev/cluster_conf/spark/spark_schedulebased_auto_scale_config.json)
- [Load Based Auto Scale](./terraform/conf/env/dev/cluster_conf/spark/spark_loadbased_autoscale_config.json) - An [example of loadbased auto scale](./terraform/conf/env/dev/cluster_conf/spark/loadbased_example.png). 
- Hive Catalog
- Log Analytics

:information_source: You can have common or different databases for different workload (Spark, Flink, and Trino). It is managed by `spark_hive_db` variable. It is mandatory to have `sql_server_name` before you can use a hive catalog.

### [Trino Cluster](./terraform/modules/trino/main.tf) 

It [creates an Apache Trino cluster](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-create-cluster) in a [cluster pool](#cluster-pool). It is dependent on [cluster-init](#cluster-init). 

The current terraform module supports following features for the HDInsight on AKS Apache Flink cluster.
- [Schedule Based Auto Scale](./terraform/conf/env/dev/cluster_conf/trino/trino_schedulebased_auto_scale_config.json)
- Hive Catalog
- Log Analytics

:information_source: You can have common or different databases for different workload (Spark, Flink, and Trino). It is managed by `trino_hive_db` variable. It is mandatory to have `sql_server_name` before you can use a hive catalog.

### [Flink Job Submission](./terraform/modules/flink-job/main.tf)

HDInsight on AKS supports user friendly [ARM Rest API](https://learn.microsoft.com/en-us/rest/api/hdinsightonaks/cluster-jobs/run-job?view=rest-hdinsightonaks-2023-06-01-preview&tabs=HTTP) to submit job and manage job. Using terraform [azapi_resource_action](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/azapi_resource_action) you can perform job action on the Apache Flink cluster.

This module allows you to create, update, cancel, stop, and delete jobs from the HDInsight on AKS Apache Flink cluster. The `flink_job_action_flag=true` and `flink_job_name` is mandatory to perform any action on the job. Terraform variable `flink_job_action` is going to control the job action (NEW, UPDATE, DELETE, CANCEL, STOP). The value for `flink_job_action` is not defined at [tfvars file](./terraform/conf/env/dev/job_conf/flink/job.tfvars), it should be supplied part of the terraform plan and apply.

Users can supply various Flink job configurations like `parallelism`, `savepoint.directory`, etc using [json configuration](./terraform/conf/env/dev/job_conf/flink/flink_job_conf.json) file.

:information_source: The terraform script is going to upload the job jar file to blob storage defined by `flink_jar_container` variable, the default value for `flink_jar_container` is flink cluster primary storage container. You can you any other conatiner to different storage account; supplied the [MSI](#user-managed-identity) should have required permissions to access the same from the cluster.
  
## Example tfvars file

 tfvars files are most common way to manage variables. 
- [Cluster tfvars](./terraform/conf/env/dev/cluster.tfvars) -  cluster initialization related variable values (like storage, MSI, key vault, etc.)
- [Log Analytics tfvars](./terraform/conf/env/dev/la.tfvars) -  Log Analytics related variable values
- [HDinsight Pool tfvars](./terraform/conf/env/dev/pool.tfvars) -  HDInsight on AKS pool related variable values (like resource group, VNet, SubNet, pool name, etc.)
- [Flink cluster](./terraform/conf/env/dev/cluster_conf/flink/) -  Flink cluster variable values (create_flink_cluster_flag=true is going to create the flink cluster)
   - [Schedule based auto scale configuration](./terraform/conf/env/dev/cluster_conf/flink/flink_ScheduleBased_auto_scale_config.json) 
   - [Flink tfvars](./terraform/conf/env/dev/cluster_conf/flink/flink.tfvars) - Flink cluster related variable values
- [Spark cluster](./terraform/conf/env/dev/cluster_conf/spark/) -  Spark cluster variable values (create_spark_cluster_flag=true is going to create the spark cluster)
   - [Schedule based auto scale configuration](./terraform/conf/env/dev/cluster_conf/spark/spark_ScheduleBased_auto_scale_config.json) 
   - [Load based auto scale configuration](./terraform/conf/env/dev/cluster_conf/spark/spark_LoadBased_autoscale_config.json) - Example is [based on](./terraform/conf/env/dev/cluster_conf/spark/loadbased_example.png)  
   - [Spark tfvars](./terraform/conf/env/dev/cluster_conf/spark/spark.tfvars) - Spark cluster related variable values
- [Trino cluster](./terraform/conf/env/dev/cluster_conf/trino/) -  Trino cluster variable values (create_trino_cluster_flag=true is going to create the Trino cluster)
   - [Schedule based auto scale configuration](./terraform/conf/env/dev/cluster_conf/trino/trino_schedulebased_auto_scale_config.json) 
   - [Trino tfvars](./terraform/conf/env/dev/cluster_conf/trino/trino.tfvars) - Trino cluster related variable values
- [Flink Job](./terraform/conf/env/dev/job_conf/flink/job.tfvars) - Flink job related variable values and [configurations](./terraform/conf/env/dev/job_conf/flink/flink_job_conf.json)

# Running Example

Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). In this example we are using Authenticating using [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli). You can make necessary changes based on your organization policy.

- `terraform init` - to initialize the terraform
- `terraform plan -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars" -var-file="conf/env/dev/cluster_conf/spark/spark.tfvars" -var-file="conf/env/dev/cluster_conf/trino/trino.tfvars" -var-file="conf/env/dev/job_conf/flink/job.tfvars" -var "env=dev"` - creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure
- `terraform apply -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars" -var-file="conf/env/dev/cluster_conf/spark/spark.tfvars" -var-file="conf/env/dev/cluster_conf/trino/trino.tfvars" -var-file="conf/env/dev/job_conf/flink/job.tfvars" -var "env=dev"`- executes the actions proposed in a Terraform plan.
- `terraform destroy -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars" -var-file="conf/env/dev/cluster_conf/spark/spark.tfvars" -var-file="conf/env/dev/cluster_conf/trino/trino.tfvars" -var-file="conf/env/dev/job_conf/flink/job.tfvars" -var "env=dev"` - It is a convenient way to destroy all remote objects managed by a particular Terraform configuration.
