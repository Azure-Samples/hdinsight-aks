

# Quickstart: Create a HDInsight on AKS Cluster Pool with the Azure CLI on Azure

This quickstart shows you how to use the PowerShell to deploy a HDInsight on AKS Cluster Pool in Azure.

## Prerequisites
Ensure that you have completed the [subscription prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-subscription) and [resource prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-resources) before creating a cluster pool.

The command New-AzHdInsightOnAksClusterPool is part of Azure PowerShell module "Az.HdInsightOnAks" and it is not installed. Run **"Install-Module Az.HdInsightOnAks"** to install it.

## Launch Azure Cloud Shell

The Azure Cloud Shell is a free interactive shell that you can use to run the steps in this article. It has common Azure tools preinstalled and configured to use with your account.

To open the Cloud Shell, just select **Try it** from the upper right corner of a code block. Select **Copy** to copy the blocks of code, paste it into the Cloud Shell, and press enter to run it.

## Create a resource group

Create an Azure resource group with [New-AzResourceGroup](https://learn.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup?view=azps-12.0.0). A resource group is a logical container into which Azure resources are deployed and managed:

```Azure PowerShell
New-AzResourceGroup -Name 'HDIonAKSPowershell' -Location 'West US 3'
```

## Create the HDInsight on AKS Cluster Pool

To create a HDInsight on AKS Cluster Pool in this resource group, use the `New-AzHdInsightOnAksClusterPool` command:
```PowerShell
New-AzHdInsightOnAksClusterPool
   -Name <String>
   -ResourceGroupName <String>
   [-SubscriptionId <String>]
   -Location <String>
   [-ClusterPoolVersion <String>]
   [-EnableLogAnalytics]
   [-LogAnalyticWorkspaceResourceId <String>]
   [-ManagedResourceGroupName <String>]
   [-NetworkProfileApiServerAuthorizedIPRange <String[]>]
   [-NetworkProfileEnablePrivateApiServer]
   [-NetworkProfileOutboundType <String>]
   [-SubnetId <String>]
   [-Tag <Hashtable>]
   [-VmSize <String>]
   [-DefaultProfile <PSObject>]
   [-AsJob]
   [-NoWait]
   [-WhatIf]
   [-Confirm]
   [<CommonParameters>]
```
Here is an actual example:
```PowerShell
$location = "West US 3"
$clusterResourceGroupName = "HDIonAKSPowershell"
$clusterpoolName = "HDIClusterPoolSample"
$vmSize = "Standard_E4s_v3"
$clusterpoolversion="1.1"

# Create the cluster pool
New-AzHdInsightOnAksClusterPool `
    -Name $clusterpoolName `
    -ResourceGroupName $clusterResourceGroupName `
    -Location $location `
    -VmSize $vmSize `
    -ClusterPoolVersion $clusterpoolversion
```

It takes a few minutes to create the HDInsight on AKS Cluster Pool. The following example output shows the create operation was successful.

Results:
<!-- expected_similarity=0.3 -->
```
AkClusterProfileAkClusterAgentPoolIdentityProfileMsiClientId   : a75ec1ff-3f7f-4f44-820c-6eaa5c8191af
AkClusterProfileAkClusterAgentPoolIdentityProfileMsiObjectId   : 13990b78-4140-4d10-b333-69bb78524375
AkClusterProfileAkClusterAgentPoolIdentityProfileMsiResourceId : /subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourcegroups/MC_hdi-44640a235566423490b9fb694d6c05a3_HDIClusterP
                                                                 oolSample_westus3/providers/Microsoft.ManagedIdentity/userAssignedIdentities/HDIClusterPoolSample-agentpool
AkClusterProfileAksClusterResourceId                           : /subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/hdi-44640a235566423490b9fb694d6c05a3/providers/Micr
                                                                 osoft.ContainerService/managedClusters/HDIClusterPoolSample
AkClusterProfileAksVersion                                     : 1.27.9
AksManagedResourceGroupName                                    : MC_hdi-44640a235566423490b9fb694d6c05a3_HDIClusterPoolSample_westus3
ComputeProfileCount                                            : 3
ComputeProfileVMSize                                           : Standard_E4s_v3
DeploymentId                                                   : 44640a235566423490b9fb694d6c05a3
Id                                                             : /subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/HDIonAKSPowershell/providers/Microsoft.HDInsight/cl
                                                                 usterpools/HDIClusterPoolSample
Location                                                       : West US 3
LogAnalyticProfileEnabled                                      : False
LogAnalyticProfileWorkspaceId                                  : 
ManagedResourceGroupName                                       : hdi-44640a235566423490b9fb694d6c05a3
Name                                                           : HDIClusterPoolSample
NetworkProfileApiServerAuthorizedIPRange                       : 
NetworkProfileEnablePrivateApiServer                           : 
NetworkProfileOutboundType                                     : 
NetworkProfileSubnetId                                         : 
ProfileClusterPoolVersion                                      : 1.1
ProvisioningState                                              : Succeeded
ResourceGroupName                                              : HDIonAKSPowershell
Status                                                         : Running
SystemDataCreatedAt                                            : 6/2/2024 11:53:01 AM
SystemDataCreatedBy                                            : guodongwang@microsoft.com
SystemDataCreatedByType                                        : User
SystemDataLastModifiedAt                                       : 6/2/2024 11:53:01 AM
SystemDataLastModifiedBy                                       : guodongwang@microsoft.com
SystemDataLastModifiedByType                                   : User
Tag                                                            : {
                                                                 }
Type                                                           : microsoft.hdinsight/clusterpools
```

## Next Steps

* [New-AzHdInsightOnAksClusterPool](https://learn.microsoft.com/en-us/powershell/module/az.hdinsightonaks/new-azhdinsightonaksclusterpool?view=azps-12.0.0)
* [Create cluster pool and cluster](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster)
