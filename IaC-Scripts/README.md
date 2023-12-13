# Terraform Scripts

## Modules
   - [Resource-group](./terraform/modules/resource-group/main.tf) - Creates Resource group
   - [Network](./terraform/modules/network/main.tf) - Creates VNet and Subnet
   - [Log Analytics](./terraform/modules/log-analytics/main.tf) - Creates Log Analytics Workspace
   - [Cluster-pool](./terraform/modules/cluster-pool/main.tf) - Creates HDInsight on AKS Cluster pool
   - [Cluster-init](./terraform/modules/cluster-init/main.tf) - Initialize cluster prerequisites
      - [User Managed Identity](./terraform/modules/identity/main.tf) - Creates an user-assigned managed identity (MSI)
      - [Storage Account](./terraform/modules/storage/main.tf) - Creates Storage account
      - [Key Vault](./terraform/modules/key-vault/main.tf) - Creates Azure Key Vault to store SQL Server credential
      - [SQL Server](./terraform/modules/sql-database/main.tf) - Creates SQL server for Hive Catalog
  - [SQL VNet](./terraform/modules/sql-vnet/main.tf) - Create rules for allowing traffic between an Azure SQL server and a subnet of a virtual network
  - [Flink](./terraform/modules/flink/main.tf) - Creates Flink cluster (Supports Schedulebased Auto scale)
  - [Spark](./terraform/modules/spark/main.tf) - Creates Spark cluster (Supports Load and Schedule Based Auto scale)
  
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

# Running Example

Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). In this example we are using Authenticating using [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli). You can make necessary changes based on your organization policy.

- `terraform init` - to initialize the terraform
- `terraform plan -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars"` - creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure
- `terraform apply -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars"`- executes the actions proposed in a Terraform plan.
- `terraform destriy -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars"` - It is a convenient way to destroy all remote objects managed by a particular Terraform configuration.
