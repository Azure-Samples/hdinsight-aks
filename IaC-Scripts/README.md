# Terraform Scripts

## Modules
   - [Resource-group](./terraform/modules/resource-group/main.tf) - Creates Resource group, if create_rg_for_pool_flag=false, It will use existing resource group.
   - [Network](./terraform/modules/network/main.tf) - Creates VNet and Subnet
   | vnet_name  |create_vnet_flag|subnet_name|create_subnet_flag|Action                      |
   |------------|----------------|-----------|------------------|----------------------------|
   |not empty   |            true|not empty  |              true|create a new Vnet and Subnet|
   |not empty   |            true|not empty  |             false|create a new Vnet and use existing Subnet|
   |not empty   |           false|not empty  |             false|use existing Vnet and Subnet|
   |not empty   |           false|not empty  |              true|use existing Vnet and create a new Subnet|
   |empty       |              NA|NA         |                NA|No VNet and SubNet|
   |not empty   |           false|empty      |                NA|No VNet and SubNet|
   - [Log Analytics](./terraform/modules/log-analytics/main.tf) - Creates Log Analytics Workspace.   
   | create_log_analytics_flag  |la_name  |Action                      |
   |----------------------------|-------  |----------------------------|
   |true                        |non empty|create a Log Analytics workspace|
   |false                       |non empty|use existing Log Analytics workspace|
   |NA                          |empty    |don't use any Log Analytics workspace|
   - [Cluster-pool](./terraform/modules/cluster-pool/main.tf) - Creates HDInsight on AKS Cluster pool
   - [Cluster-init](./terraform/modules/cluster-init/main.tf) - Initialize cluster prerequisites
      - [User Managed Identity](./terraform/modules/identity/main.tf) - Creates an user-assigned managed identity (MSI)
      - [Storage Account](./terraform/modules/storage/main.tf) - Creates Storage account
      - [Key Vault](./terraform/modules/key-vault/main.tf) - Creates Azure Key Vault to store SQL Server credential
      - [SQL Server](./terraform/modules/sql-database/main.tf) - Creates SQL server for Hive Catalog
  - [SQL VNet](./terraform/modules/sql-vnet/main.tf) - Create rules for allowing traffic between an Azure SQL server and a subnet of a virtual network
  - [Flink](./terraform/modules/flink/main.tf) - Creates Flink cluster (Supports Schedulebased Auto scale), you can enable or disable of creation of the cluster using create_flink_cluster_flag
  - [Spark](./terraform/modules/spark/main.tf) - Creates Spark cluster (Supports Load and Schedule Based Auto scale), you can enable or disable of creation of the cluster using create_spark_cluster_flag
  - [Trino](./terraform/modules/trino/main.tf) - Creates Trino cluster (Supports Load and Schedule Based Auto scale), you can enable or disable of creation of the cluster using create_trino_cluster_flag
  
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

# Running Example

Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). In this example we are using Authenticating using [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli). You can make necessary changes based on your organization policy.

- `terraform init` - to initialize the terraform
- `terraform plan -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars" -var-file="conf/env/dev/cluster_conf/spark/spark.tfvars" -var-file="conf/env/dev/cluster_conf/trino/trino.tfvars"` - creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure
- `terraform apply -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars" -var-file="conf/env/dev/cluster_conf/spark/spark.tfvars" -var-file="conf/env/dev/cluster_conf/trino/trino.tfvars"`- executes the actions proposed in a Terraform plan.
- `terraform destroy -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars" -var-file="conf/env/dev/cluster_conf/spark/spark.tfvars" -var-file="conf/env/dev/cluster_conf/trino/trino.tfvars""` - It is a convenient way to destroy all remote objects managed by a particular Terraform configuration.
