# Terraform
subscription                = ""
client_id                   = ""
client_secret               = ""
tenant_id                   = ""
# HDI on AKS Pool resource group, this is where pool and cluster will be created
rg_name                     = "terraform_hdi_on_aks"
# indicates whether you want to use existing resource group or create a new one rg_name
create_rg_for_pool          = false
# Location/Region where you would like to create all your resources
location_name               = "eastus2"
# Pool name for HDI on AKS, use HDInsight on AKS documentation for the naming rules
hdi_on_aks_pool_name        = "terraform-hdi-pool"
# Virtual machine size for the cluster pool based on your requirement. Use HDInsight on AKS documentation for detail.
pool_node_vm_size           = "Standard_D4as_v4"
# Managed resource group holds ancillary resources created by HDInsight on AKS.
# By default, two managed resource groups are created with cluster pool creation.
# RG1 = <Default name {hdi-deploymentId of cluster pool}> - To hold ancillary resources for HDInsight on AKS
# RG2 = <MC_{RG1}_{cluster pool name}_{region}> - To hold infrastructure resources for Azure Kubernetes Services
# When you create a pool optionally you can pass RG1 to satisfy your organization’s resource group name policies.
# if Name is test1 then MC_test1_managed_<hdi_on_aks_pool_name>_<location_name> Resource Group will be created for AKS
# if you don't want to use any custom RG1, pass empty string
managed_resource_group_name = "test1"
# VNet and Subnet related variables
vnet_name                   = "testvnet"
vnet_rg_name                = "terraform_hdi_on_aks"
subnet_name                 = "default"
# if vnet_name or subnet_name is empty these will not have any impact
create_vnet                 = true
create_subnet               = true
# Cluster related variables
#user_assigned_identity_name = "arunterraformtest"