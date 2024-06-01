

# Quickstart: Create a HDInsight on AKS Cluster Pool with the Azure CLI on Azure

This quickstart shows you how to use the Azure CLI to deploy a HDInsight on AKS Cluster Pool in Azure. The Azure CLI is used to create and manage Azure resources via either the command line or scripts.

## Launch Azure Cloud Shell

The Azure Cloud Shell is a free interactive shell that you can use to run the steps in this article. It has common Azure tools preinstalled and configured to use with your account. 

To open the Cloud Shell, just select **Try it** from the upper right corner of a code block. You can also open Cloud Shell in a separate browser tab by going to [https://shell.azure.com/bash](https://shell.azure.com/bash). Select **Copy** to copy the blocks of code, paste it into the Cloud Shell, and select **Enter** to run it.

If you prefer to install and use the CLI locally, this quickstart requires Azure CLI version 2.0.30 or later. Run `az --version` to find the version. If you need to install or upgrade, see [Install Azure CLI]( /cli/azure/install-azure-cli).

## Define environment variables

The first step is to define the environment variables. Environment variables are commonly used in Linux to centralize configuration data to improve consistency and maintainability of the system. Create the following environment variables to specify the names of resources that you create later in this tutorial:

```bash
export RecourceGroup="HDIonAKSCLI"
export REGION=EastUS
export AKSClusterPoolName="AKSClusterPoolSample"
export nodetype="Standard_E4s_v3"
export clusterversion="1.1"
```

## Log in to Azure using the CLI

In order to run commands in Azure using the CLI, you need to log in first. Log in using the `az login` command.

## Create a resource group

A resource group is a container for related resources. All resources must be placed in a resource group. The [az group create](/cli/azure/group) command creates a resource group with the previously defined $MY_RESOURCE_GROUP_NAME and $REGION parameters.

```bash
az group create --name $RecourceGroup --location $REGION
```

Results:

<!-- expected_similarity=0.3 -->
```json
{
  "id": "/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/HDIonAKSCLI",
  "location": "eastus",
  "managedBy": null,
  "name": "HDIonAKSCLI",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

## Create the HDInsight on AKS Cluster Pool

To create a HDInsight on AKS Cluster Pool in this resource group, use the `az hdinsight-on-aks clusterpool create` command:
```bash
az hdinsight-on-aks clusterpool create --cluster-pool-name
                                       --resource-group
                                       [--api-server-authorized-ip-ranges]
                                       [--cluster-pool-version]
                                       [--enable-log-analytics {0, 1, f, false, n, no, t, true, y, yes}]
                                       [--la-workspace-id]
                                       [--location]
                                       [--managed-rg-name]
                                       [--no-wait {0, 1, f, false, n, no, t, true, y, yes}]
                                       [--outbound-type {loadBalancer, userDefinedRouting}]
                                       [--private-server-enabled {0, 1, f, false, n, no, t, true, y, yes}]
                                       [--subnet-id]
                                       [--tags]
                                       [--workernode-size]
```
Here is an actual example:
```bash
az hdinsight-on-aks clusterpool create -g $RecourceGroup -n $AKSClusterPoolName -l $REGION --workernode-size $nodetype --version $clusterversion
```

It takes a few minutes to create the HDInsight on AKS Cluster Pool. The following example output shows the create operation was successful.

Results:
<!-- expected_similarity=0.3 -->
```json
{
  "aksClusterProfile": {
    "aksClusterAgentPoolIdentityProfile": {
      "msiClientId": "1b1b591d-0c11-4902-a5f0-922140684833",
      "msiObjectId": "e285de87-073e-4784-8c3f-271752c0d80e",
      "msiResourceId": "/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourcegroups/MC_hdi-bdf17e29a1254a989429d7b344073b66_AKSClusterPoolSample_eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/AKSClusterPoolSample-agentpool"
    },
    "aksClusterResourceId": "/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/hdi-bdf17e29a1254a989429d7b344073b66/providers/Microsoft.ContainerService/managedClusters/AKSClusterPoolSample",
    "aksVersion": "1.27.9"
  },
  "aksManagedResourceGroupName": "MC_hdi-bdf17e29a1254a989429d7b344073b66_AKSClusterPoolSample_eastus",
  "clusterPoolProfile": {
    "clusterPoolVersion": "1.1"
  },
  "computeProfile": {
    "count": 3,
    "vmSize": "Standard_D4as_v4"
  },
  "deploymentId": "bdf17e29a1254a989429d7b344073b66",
  "id": "/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/HDIonAKSCLI/providers/Microsoft.HDInsight/clusterpools/AKSClusterPoolSample",
  "location": "EastUS",
  "managedResourceGroupName": "hdi-bdf17e29a1254a989429d7b344073b66",
  "name": "AKSClusterPoolSample",
  "provisioningState": "Succeeded",
  "resourceGroup": "HDIonAKSCLI",
  "status": "Running",
  "systemData": {
    "createdAt": "2024-05-31T15:02:42.2172295Z",
    "createdBy": "guodongwang@microsoft.com",
    "createdByType": "User",
    "lastModifiedAt": "2024-05-31T15:02:42.2172295Z",
    "lastModifiedBy": "guodongwang@microsoft.com",
    "lastModifiedByType": "User"
  },
  "type": "microsoft.hdinsight/clusterpools"
}
```

## Next Steps

* [az hdinsight-on-aks clusterpool](https://learn.microsoft.com/en-us/cli/azure/hdinsight-on-aks/clusterpool?view=azure-cli-latest)
* [Create cluster pool and cluster](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster)
