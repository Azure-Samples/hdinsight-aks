

# Quickstart: Create a Flink Cluster with the Azure CLI on Azure

This quickstart shows you how to use the Azure CLI to deploy a Flink cluster in HDInsight on AKS Pool. The Azure CLI is used to create and manage Azure resources via either the command line or scripts.

## Prerequisites
Complete the prerequisites in the following sections:
- [subscription prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-subscription)
- [resource prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-resources)
- [Create a cluster pool](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster#create-a-cluster-pool)

## Launch Azure Cloud Shell

The Azure Cloud Shell is a free interactive shell that you can use to run the steps in this article. It has common Azure tools preinstalled and configured to use with your account. 

To open the Cloud Shell, just select **Try it** from the upper right corner of a code block. You can also open Cloud Shell in a separate browser tab by going to [https://shell.azure.com/bash](https://shell.azure.com/bash). Select **Copy** to copy the blocks of code, paste it into the Cloud Shell, and select **Enter** to run it.

If you prefer to install and use the CLI locally, this quickstart requires Azure CLI version 2.0.30 or later. Run `az --version` to find the version. If you need to install or upgrade, see [Install Azure CLI]( /cli/azure/install-azure-cli).

## Define environment variables

The first step is to define the environment variables. Environment variables are commonly used in Linux to centralize configuration data to improve consistency and maintainability of the system. Create the following environment variables to specify the names of resources that you create later in this tutorial:

```bash
export clustername="FlinkSample"
export clusterpoolname="AKSClusterPoolSample"
export REGION=eastus
export RecourceGroup="HDIonAKSCLI"
export MSIOID="2f64df01-29a7-4a68-bb35-595084ac2fff"
export MSIClientID="d3497790-0d09-4fe5-987e-d9b08ae5d275"
export MSI="/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/Hilotest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/guodongwangMSI"
export clusterversion=1.1.1
export ossversion=1.17.0
export flinkstorage="abfs://flinktest@guodongwangstore.dfs.core.windows.net"
```

## Log in to Azure using the CLI

In order to run commands in Azure using the CLI, you need to log in first. Log in using the `az login` command.

## Create Flink cluster in the HDInsight on AKS Cluster Pool

To create a Flink cluster, use the `az hdinsight-on-aks cluster create` command:
```bash
az hdinsight-on-aks cluster create --cluster-name
                                   --cluster-pool-name
                                   --resource-group
                                   [--application-log-std-error-enabled {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--application-log-std-out-enabled {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--assigned-identity-client-id]
                                   [--assigned-identity-id]
                                   [--assigned-identity-object-id]
                                   [--authorization-group-id]
                                   [--authorization-user-id]
                                   [--autoscale-profile-graceful-decommission-timeout]
                                   [--autoscale-profile-type {LoadBased, ScheduleBased}]
                                   [--cluster-type]
                                   [--cluster-version]
                                   [--cooldown-period]
                                   [--coord-debug-port]
                                   [--coord-debug-suspend {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--coordinator-debug-enabled {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--coordinator-high-availability-enabled {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--db-connection-authentication-mode {IdentityAuth, SqlAuth}]
                                   [--deployment-mode {Application, Session}]
                                   [--enable-autoscale {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--enable-la-metrics {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--enable-log-analytics {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--enable-prometheu {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--enable-worker-debug {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--flink-db-auth-mode {IdentityAuth, SqlAuth}]
                                   [--flink-hive-catalog-db-connection-password-secret]
                                   [--flink-hive-catalog-db-connection-url]
                                   [--flink-hive-catalog-db-connection-user-name]
                                   [--flink-storage-key]
                                   [--flink-storage-uri]
                                   [--history-server-cpu]
                                   [--history-server-memory]
                                   [--internal-ingress {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--job-manager-cpu]
                                   [--job-manager-memory]
                                   [--job-spec]
                                   [--kafka-profile]
                                   [--key-vault-id]
                                   [--llap-profile]
                                   [--loadbased-config-max-nodes]
                                   [--loadbased-config-min-nodes]
                                   [--loadbased-config-poll-interval]
                                   [--loadbased-config-scaling-rules]
                                   [--location]
                                   [--no-wait {0, 1, f, false, n, no, t, true, y, yes}]
                                   [--nodes]
                                   [--num-replicas]
                                   [--oss-version]
                                   [--ranger-plugin-profile]
                                   [--ranger-profile]
                                   [--schedule-based-config-default-count]
                                   [--schedule-based-config-schedule]
                                   [--schedule-based-config-time-zone]
                                   [--script-action-profiles]
                                   [--secret-reference]
                                   [--service-configs]
                                   [--spark-hive-catalog-db-name]
                                   [--spark-hive-catalog-db-password-secret]
                                   [--spark-hive-catalog-db-server-name]
                                   [--spark-hive-catalog-db-user-name]
                                   [--spark-hive-catalog-key-vault-id]
                                   [--spark-hive-catalog-thrift-url]
                                   [--spark-storage-url]
                                   [--ssh-profile-count]
                                   [--stub-profile]
                                   [--tags]
                                   [--task-manager-cpu]
                                   [--task-manager-memory]
                                   [--trino-hive-catalog]
                                   [--trino-plugins-spec]
                                   [--trino-profile-user-plugins-telemetry-spec]
                                   [--user-plugins-spec]
                                   [--worker-debug-port]
                                   [--worker-debug-suspend {0, 1, f, false, n, no, t, true, y, yes}]
```
Here is an actual example:
```bash
az hdinsight-on-aks cluster create \
    -n $clustername \
    --cluster-pool-name $clusterpoolname \
    -g $RecourceGroup \
    -l $REGION \
    --assigned-identity-object-id $MSIOID \
    --assigned-identity-client-id $MSIClientID \
    --authorization-user-id d7f2e9c3-81c9-4af6-9695-c2962a1d6bd6 \
    --assigned-identity-id $MSI \
    --cluster-type Flink  \
    --cluster-version $clusterversion \
    --oss-version $ossversion \
    --nodes ["{'Count':'3','Type':'Worker','VMSize':'Standard_D8d_v5'}"]
    --flink-storage-uri $flinkstorage \
    --job-manager-cpu 1 \
    --job-manager-memory 2000 \
    --task-manager-cpu 6 \
    --task-manager-memory 49016

```

It takes a few minutes to create the Flink cluster. The following example output shows the create operation was successful.

Results:
<!-- expected_similarity=0.3 -->
```json
{
  "clusterProfile": {
    "authorizationProfile": {
      "userIds": [
        "d7f2e9c3-81c9-4af6-9695-c2962a1d6bd6"
      ]
    },
    "clusterVersion": "1.1.1",
    "components": [
      {
        "name": "Flink",
        "version": "1.17.0"
      },
      {
        "name": "Hive Metastore",
        "version": "3.1.2"
      }
    ],
    "connectivityProfile": {
      "web": {
        "fqdn": "FlinkSample.AKSClusterPoolSample.0b130652e15b417e885a050c9a3024a2.eastus.hdinsightaks.net"
      }
    },
    "flinkProfile": {
      "jobManager": {
        "cpu": 1.0,
        "memory": 4096
      },
      "storage": {
        "storageUri": "abfs://flinksample@guodongwangstore.dfs.core.windows.net"
      },
      "taskManager": {
        "cpu": 1.0,
        "memory": 4096
      }
    },
    "identityProfile": {
      "msiClientId": "d3497790-0d09-4fe5-987e-d9b08ae5d275",
      "msiObjectId": "2f64df01-29a7-4a68-bb35-595084ac2fff",
      "msiResourceId": "/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/Hilotest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/guodongwangMSI"
    },
    "ossVersion": "1.17.0"
  },
  "clusterType": "Flink",
  "computeProfile": {
    "nodes": [
      {
        "count": 2,
        "type": "Head",
        "vmSize": "Standard_E8d_v5"
      },
      {
        "count": 3,
        "type": "Worker",
        "vmSize": "Standard_E8d_v5"
      }
    ]
  },
  "deploymentId": "f7d77bdf5d9f4ff29b53bb28ad5eece5",
  "id": "/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/HDIonAKSCLI/providers/Microsoft.HDInsight/clusterpools/AKSClusterPoolSample/clusters/FlinkSample",
  "location": "eastus",
  "name": "FlinkSample",
  "provisioningState": "Succeeded",
  "resourceGroup": "HDIonAKSCLI",
  "status": "Running",
  "systemData": {
    "createdAt": "2024-06-02T13:17:38.2529862Z",
    "createdBy": "guodongwang@microsoft.com",
    "createdByType": "User",
    "lastModifiedAt": "2024-06-02T13:17:38.2529862Z",
    "lastModifiedBy": "guodongwang@microsoft.com",
    "lastModifiedByType": "User"
  },
  "type": "microsoft.hdinsight/clusterpools/clusters"
}
```

## Next Steps

* [az hdinsight-on-aks cluster create](https://learn.microsoft.com/en-us/cli/azure/hdinsight-on-aks/cluster?view=azure-cli-latest#az-hdinsight-on-aks-cluster-create)
* [Create an Apache Flink® cluster in HDInsight on AKS with Azure portal](https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal)
