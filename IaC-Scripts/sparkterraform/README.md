# HDInsight on AKS - Apache Spark Terraform Scripts (Minimal Version)

These terraform scripts will let you manage your HDInsight on AKS infrastructure using code for the Apache Spark cluster. 
The following functionality is supported by this module:

- Create Resource Group to hold all require resources
- Create Cluster Pool
- Create VNet and SubNet
- Create User-assigned managed identity
- Create Storage Account
- Create Default Spark Storage Container
- Create Spark Cluster

You can supply your subscription Id from [spark.tfvars](./conf/spark.tfvars) file or from CLI. 

If you would like to use advance feature functionalities like Hive Catalog, Log Analytics, etc. please refer this [code](../terraform) to enhance this module.

:information_source: - Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). You can make necessary changes based on your organization policy

# Running Example

Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). In this example we are using Authenticating using [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli). You can make necessary changes based on your organization policy.

- `terraform init` - initialization
- `terraform plan -var-file="conf/spark.tfvars"` - creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure
- `terraform apply -var-file="conf/spark.tfvars"`- executes the actions proposed in a Terraform plan.
- `terraform destroy -var-file="conf/spark.tfvars"` - It is a convenient way to destroy all remote objects managed by a particular Terraform configuration.
