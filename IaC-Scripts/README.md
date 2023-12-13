# Terraform Scripts

- [Example tfvars file](./terraform/conf/example.tfvars)
- Modules
   - [resource-group](./terraform/modules/resource-group/main.tf) - Creates Resource group
   - [network](./terraform/modules/network/main.tf) - Creates VNet and Subnet
   - [Log Analytics](./terraform/modules/log-analytics/main.tf) - Creates Log Analytics Workspace
   - [cluster-pool](./terraform/modules/cluster-pool/main.tf) - Creates HDInsight on AKS Cluster pool
   - [cluster-init](./terraform/modules/cluster-init/main.tf) - Initialize cluster prerequisites
      - [User Managed Identity](./terraform/modules/identity/main.tf) - Creates an user-assigned managed identity (MSI)
      - [Storage Account](./terraform/modules/storage/main.tf) - Creates Storage account
      - [Key Vault](./terraform/modules/key-vault/main.tf) - Creates Azure Key Vault to store SQL Server credential
      - [SQL Server](./terraform/modules/sql-database/main.tf) - Creates SQL server for Hive Catalog
  - [SQL VNet](./terraform/modules/sql-vnet/main.tf) - Create rules for allowing traffic between an Azure SQL server and a subnet of a virtual network
  - [Flink](./terraform/modules/flink/main.tf)

# Running Example

Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). In this example we are using Authenticating using [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli). You can make necessary changes based on your organization policy.

- `terraform init` - to initialize the terraform
- `terraform plan -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars"` - creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure
- `terraform apply -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars"`- executes the actions proposed in a Terraform plan.
- `terraform destriy -var-file="conf/env/dev/cluster.tfvars" -var-file="conf/env/dev/pool.tfvars" -var-file="conf/env/dev/cluster_conf/flink/flink.tfvars" -var-file="conf/env/dev/la.tfvars"` - It is a convenient way to destroy all remote objects managed by a particular Terraform configuration.
