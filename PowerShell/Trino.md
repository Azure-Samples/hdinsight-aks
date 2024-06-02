

# Quickstart: Create a Trino Cluster with the Powershell

This quickstart shows you how to use the PowerShell to deploy a Trino cluster in HDInsight on AKS Pool.

## Prerequisites
Complete the prerequisites in the following sections:
- [subscription prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-subscription)
- [resource prerequisites](https://learn.microsoft.com/en-us/azure/hdinsight-aks/prerequisites-resources)
- [Create a cluster pool](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster#create-a-cluster-pool)

## Launch Azure Cloud Shell

The Azure Cloud Shell is a free interactive shell that you can use to run the steps in this article. It has common Azure tools preinstalled and configured to use with your account.

To open the Cloud Shell, just select **Try it** from the upper right corner of a code block. Select **Copy** to copy the blocks of code, paste it into the Cloud Shell, and press enter to run it.

## Create Trino cluster in the HDInsight on AKS Cluster Pool

To create a Trino cluster, use the `New-AzHdInsightOnAksCluster` command:
```PowerShell
New-AzHdInsightOnAksCluster
   -Name <String>
   -PoolName <String>
   -ResourceGroupName <String>
   [-SubscriptionId <String>]
   -Location <String>
   [-ApplicationLogStdErrorEnabled]
   [-ApplicationLogStdOutEnabled]
   [-AssignedIdentityClientId <String>]
   [-AssignedIdentityObjectId <String>]
   [-AssignedIdentityResourceId <String>]
   [-AuthorizationGroupId <String[]>]
   [-AuthorizationUserId <String[]>]
   [-AutoscaleProfileAutoscaleType <String>]
   [-AutoscaleProfileEnabled]
   [-AutoscaleProfileGracefulDecommissionTimeout <Int32>]
   [-ClusterAccessProfileEnableInternalIngress]
   [-ClusterType <String>]
   [-ClusterVersion <String>]
   [-ComputeProfileNode <INodeProfile[]>]
   [-CoordinatorDebugEnable]
   [-CoordinatorDebugPort <Int32>]
   [-CoordinatorDebugSuspend]
   [-CoordinatorHighAvailabilityEnabled]
   [-DatabaseHost <String>]
   [-DatabaseName <String>]
   [-DatabasePasswordSecretRef <String>]
   [-DatabaseUsername <String>]
   [-DiskStorageDataDiskSize <Int32>]
   [-DiskStorageDataDiskType <String>]
   [-EnableLogAnalytics]
   [-FlinkHiveCatalogDbConnectionUrl <String>]
   [-FlinkHiveCatalogDbPasswordSecretName <String>]
   [-FlinkHiveCatalogDbUserName <String>]
   [-FlinkProfileDeploymentMode <String>]
   [-FlinkStorageUrl <String>]
   [-FlinkTaskManagerReplicaCount <Int32>]
   [-HistoryServerCpu <Single>]
   [-HistoryServerMemory <Int64>]
   [-HiveMetastoreDbConnectionAuthenticationMode <String>]
   [-JobManagerCpu <Single>]
   [-JobManagerMemory <Int64>]
   [-JobSpecArg <String>]
   [-JobSpecEntryClass <String>]
   [-JobSpecJarName <String>]
   [-JobSpecJobJarDirectory <String>]
   [-JobSpecSavePointName <String>]
   [-JobSpecUpgradeMode <String>]
   [-KafkaProfileEnableKRaft]
   [-KafkaProfileEnablePublicEndpoint]
   [-KafkaProfileRemoteStorageUri <String>]
   [-KeyVaultResourceId <String>]
   [-LlapProfile <Hashtable>]
   [-LoadBasedConfigCooldownPeriod <Int32>]
   [-LoadBasedConfigMaxNode <Int32>]
   [-LoadBasedConfigMinNode <Int32>]
   [-LoadBasedConfigPollInterval <Int32>]
   [-LoadBasedConfigScalingRule <IScalingRule[]>]
   [-LogAnalyticProfileMetricsEnabled]
   [-MetastoreSpecDbConnectionAuthenticationMode <String>]
   [-OssVersion <String>]
   [-PrometheuProfileEnabled]
   [-RangerAdmin <String[]>]
   [-RangerAuditStorageAccount <String>]
   [-RangerPluginProfileEnabled]
   [-RangerUsersyncEnabled]
   [-RangerUsersyncGroup <String[]>]
   [-RangerUsersyncMode <String>]
   [-RangerUsersyncUser <String[]>]
   [-RangerUsersyncUserMappingLocation <String>]
   [-ScheduleBasedConfigDefaultCount <Int32>]
   [-ScheduleBasedConfigSchedule <ISchedule[]>]
   [-ScheduleBasedConfigTimeZone <String>]
   [-ScriptActionProfile <IScriptActionProfile[]>]
   [-SecretReference <ISecretReference[]>]
   [-ServiceConfigsProfile <IClusterServiceConfigsProfile[]>]
   [-SparkHiveCatalogDbName <String>]
   [-SparkHiveCatalogDbPasswordSecretName <String>]
   [-SparkHiveCatalogDbServerName <String>]
   [-SparkHiveCatalogDbUserName <String>]
   [-SparkHiveCatalogKeyVaultId <String>]
   [-SparkStorageUrl <String>]
   [-SparkThriftUrl <String>]
   [-SshProfileCount <Int32>]
   [-StorageHivecatalogName <String>]
   [-StorageHivecatalogSchema <String>]
   [-StoragePartitionRetentionInDay <Int32>]
   [-StoragePath <String>]
   [-StubProfile <Hashtable>]
   [-Tag <Hashtable>]
   [-TaskManagerCpu <Single>]
   [-TaskManagerMemory <Int64>]
   [-TrinoHiveCatalog <IHiveCatalogOption[]>]
   [-TrinoProfileUserPluginsSpecPlugin <ITrinoUserPlugin[]>]
   [-WorkerDebugEnable]
   [-WorkerDebugPort <Int32>]
   [-WorkerDebugSuspend]
   [-DefaultProfile <PSObject>]
   [-AsJob]
   [-NoWait]
   [-WhatIf]
   [-Confirm]
   [<CommonParameters>]
```
Here is a simple example:
```PowerShell
# Create Simple Trino Cluster
$clusterPoolName="HDIClusterPoolSample";
$resourceGroupName="HDIonAKSPowershell";
$location="West US 3";

$clusterType="Trino"
# Get available cluster version based the command Get-AzHdInsightOnAksAvailableClusterVersion
$clusterVersion= (Get-AzHdInsightOnAksAvailableClusterVersion -Location $location | Where-Object {$_.ClusterType -eq $clusterType})[0]

$msiResourceId="/subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/Hilotest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/guodongwangMSI";
$msiClientId="d3497790-0d09-4fe5-987e-d9b08ae5d275";
$msiObjectId="2f64df01-29a7-4a68-bb35-595084ac2fff";

$userId="d7f2e9c3-81c9-4af6-9695-c2962a1d6bd6";

# create node profile
$vmSize="Standard_E8ads_v5";
$workerCount=5;

$nodeProfile = New-AzHdInsightOnAksNodeProfileObject -Type Worker -Count $workerCount -VMSize $vmSize

$clusterName="TrinoPowershell";

New-AzHdInsightOnAksCluster -Name $clusterName `
                            -PoolName $clusterPoolName `
                            -ResourceGroupName $resourceGroupName `
                            -Location $location `
                            -ClusterType $clusterType `
                            -ClusterVersion $clusterVersion.ClusterVersionValue `
                            -OssVersion $clusterVersion.OssVersion `
                            -AssignedIdentityResourceId $msiResourceId `
                            -AssignedIdentityClientId $msiClientId `
                            -AssignedIdentityObjectId $msiObjectId `
                            -ComputeProfileNode $nodeProfile `
                            -AuthorizationUserId $userId
```

It takes a few minutes to create the Trino cluster. The following example output shows the create operation was successful.

Results:
<!-- expected_similarity=0.3 -->
```
AccessProfileEnableInternalIngress          : False
AccessProfilePrivateLinkServiceId           : 
ApplicationLogStdErrorEnabled               : 
ApplicationLogStdOutEnabled                 : 
AuthorizationProfileGroupId                 : 
AuthorizationProfileUserId                  : {d7f2e9c3-81c9-4af6-9695-c2962a1d6bd6}
AutoscaleProfileAutoscaleType               : 
AutoscaleProfileEnabled                     : False
AutoscaleProfileGracefulDecommissionTimeout : 
ClusterType                                 : Trino
ComputeProfileNode                          : {{
                                                "type": "Head",
                                                "vmSize": "Standard_E8ads_v5",
                                                "count": 2
                                              }, {
                                                "type": "Worker",
                                                "vmSize": "Standard_E8ads_v5",
                                                "count": 5
                                              }}
ConnectivityEndpointBootstrapServerEndpoint : 
ConnectivityEndpointBrokerEndpoint          : 
ConnectivityProfileSsh                      : 
CoordinatorDebugEnable                      : 
CoordinatorDebugPort                        : 
CoordinatorDebugSuspend                     : 
CoordinatorHighAvailabilityEnabled          : 
DatabaseHost                                : 
DatabaseName                                : 
DatabasePasswordSecretRef                   : 
DatabaseUsername                            : 
DeploymentId                                : c1837758df474fbd993e64e577f34318
DiskStorageDataDiskSize                     : 0
DiskStorageDataDiskType                     : 
FlinkProfileDeploymentMode                  : 
FlinkProfileNumReplica                      : 
HistoryServerCpu                            : 0
HistoryServerMemory                         : 0
HiveMetastoreDbConnectionAuthenticationMode : 
HiveMetastoreDbConnectionPasswordSecret     : 
HiveMetastoreDbConnectionUrl                : 
HiveMetastoreDbConnectionUserName           : 
Id                                          : /subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/HDIonAKSPowershell/providers/Microsoft.HDInsight/clusterpools/HDIClusterPoolSample/clusters/
                                              TrinoPowershell
IdentityMsiClientId                         : 
IdentityMsiObjectId                         : 
IdentityMsiResourceId                       : 
IdentityProfileMsiClientId                  : d3497790-0d09-4fe5-987e-d9b08ae5d275
IdentityProfileMsiObjectId                  : 2f64df01-29a7-4a68-bb35-595084ac2fff
IdentityProfileMsiResourceId                : /subscriptions/0b130652-e15b-417e-885a-050c9a3024a2/resourceGroups/Hilotest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/guodongwangMSI
JobManagerCpu                               : 0
JobManagerMemory                            : 0
JobSpecArg                                  : 
JobSpecEntryClass                           : 
JobSpecJarName                              : 
JobSpecJobJarDirectory                      : 
JobSpecSavePointName                        : 
JobSpecUpgradeMode                          : 
KafkaProfileEnableKRaft                     : 
KafkaProfileEnablePublicEndpoint            : 
KafkaProfileRemoteStorageUri                : 
LoadBasedConfigCooldownPeriod               : 
LoadBasedConfigMaxNode                      : 0
LoadBasedConfigMinNode                      : 0
LoadBasedConfigPollInterval                 : 
LoadBasedConfigScalingRule                  : 
Location                                    : West US 3
LogAnalyticProfileEnabled                   : False
LogAnalyticProfileMetricsEnabled            : 
MetastoreSpecDbConnectionAuthenticationMode : 
MetastoreSpecDbName                         : 
MetastoreSpecDbPasswordSecretName           : 
MetastoreSpecDbServerHost                   : 
MetastoreSpecDbUserName                     : 
MetastoreSpecKeyVaultId                     : 
MetastoreSpecThriftUrl                      : 
Name                                        : TrinoPowershell
ProfileClusterVersion                       : 1.1.1
ProfileComponent                            : {{
                                                "name": "Trino",
                                                "version": "426"
                                              }, {
                                                "name": "Hive metastore",
                                                "version": "3.1.2"
                                              }}
ProfileLlapProfile                          : {
                                              }
ProfileOssVersion                           : 0.426.0
ProfileScriptActionProfile                  : 
ProfileServiceConfigsProfile                : 
ProfileStubProfile                          : {
                                              }
PrometheuProfileEnabled                     : False
ProvisioningState                           : Succeeded
RangerAdmin                                 : 
RangerAuditStorageAccount                   : 
RangerPluginProfileEnabled                  : False
RangerUsersyncEnabled                       : 
RangerUsersyncGroup                         : 
RangerUsersyncMode                          : 
RangerUsersyncUser                          : 
RangerUsersyncUserMappingLocation           : 
ResourceGroupName                           : HDIonAKSPowershell
ScheduleBasedConfigDefaultCount             : 0
ScheduleBasedConfigSchedule                 : 
ScheduleBasedConfigTimeZone                 : 
SecretProfileKeyVaultResourceId             : 
SecretProfileSecret                         : 
SparkProfileDefaultStorageUrl               : 
SparkProfileUserPluginsSpecPlugin           : 
SshProfileCount                             : 0
SshProfilePodPrefix                         : 
Status                                      : Running
StorageHivecatalogName                      : 
StorageHivecatalogSchema                    : 
StoragePartitionRetentionInDay              : 
StoragePath                                 : 
StorageStoragekey                           : 
StorageUri                                  : 
SystemDataCreatedAt                         : 6/2/2024 12:15:18 PM
SystemDataCreatedBy                         : guodongwang@microsoft.com
SystemDataCreatedByType                     : User
SystemDataLastModifiedAt                    : 6/2/2024 12:15:18 PM
SystemDataLastModifiedBy                    : guodongwang@microsoft.com
SystemDataLastModifiedByType                : User
Tag                                         : {
                                              }
TaskManagerCpu                              : 0
TaskManagerMemory                           : 0
TrinoProfileCatalogOptionsHive              : 
TrinoProfileUserPluginsSpecPlugin           : 
Type                                        : microsoft.hdinsight/clusterpools/clusters
WebFqdn                                     : TrinoPowershell.HDIClusterPoolSample.0b130652e15b417e885a050c9a3024a2.westus3.hdinsightaks.net
WebPrivateFqdn                              : 
WorkerDebugEnable                           : 
WorkerDebugPort                             : 
WorkerDebugSuspend                          : 
```

## Next Steps

* [New-AzHdInsightOnAksCluster](https://learn.microsoft.com/en-us/powershell/module/az.hdinsightonaks/new-azhdinsightonakscluster?view=azps-12.0.0)
* [Create a Trino cluster in the Azure portal](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-create-cluster)
