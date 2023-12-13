# environment
env                         = "dev"
# use prefix and suffix for resource group name and managed identity name
prefix                      = "terraform"
suffix                      = "hdionaks"
# HDI on AKS Pool resource group, this is where pool and cluster will be created
rg_name                     = "demo"
# indicates whether you want to use existing resource group for cluster, storage, managed identity or create a new one
create_rg_for_pool_flag     = true
# Location/Region where you would like to create all your resources
location_name               = "eastus2"
# Pool name for HDI on AKS, use HDInsight on AKS documentation for the naming rules
hdi_on_aks_pool_name        = "demo-hdi-pool"
# Virtual machine size for the cluster pool based on your requirement. Use HDInsight on AKS documentation for detail.
pool_node_vm_size           = "Standard_D4as_v4"
# Managed resource group holds ancillary resources created by HDInsight on AKS.
# By default, two managed resource groups are created with cluster pool creation.
# RG1 = <Default name {hdi-deploymentId of cluster pool}> - To hold ancillary resources for HDInsight on AKS
# RG2 = <MC_{RG1}_{cluster pool name}_{region}> - To hold infrastructure resources for Azure Kubernetes Services
# When you create a pool optionally you can pass RG1 to satisfy your organization’s resource group name policies.
# if Name is test1 then MC_test1_<hdi_on_aks_pool_name>_<location_name> Resource Group will be created for AKS
# if you don't want to use any custom RG1, pass empty string
managed_resource_group_name = "hdi-prim-n"
# VNet and Subnet related variables (no prefix and suffix)
vnet_name                   = "hilovnet"
# if VNet should be created it will be created in rg_name (prefix_rg_name_suffix)
vnet_rg_name                = "terraform_demo_hdionaks"
subnet_name                 = "default"
# if vnet_name or subnet_name is empty these will not have any impact
# we need create_vnet_flag to check if the given vnet_name is exist or need to create a new one
# this is require because datasource will throw error if the resource is not exist
create_vnet_flag            = true
create_subnet_flag          = true
