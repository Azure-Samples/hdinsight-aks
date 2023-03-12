# Create resource group
az group create --location $REGION --name $RESOURCE_GROUP_NAME

# Create AKS cluster
az \
aks create \
-g $RESOURCE_GROUP_NAME \
-n $CLUSTER_NAME \
--node-vm-size Standard_DS2_v2 \
--node-count 3 \
--enable-managed-identity \
--assign-identity $MANAGED_IDENTITY_RESOURCE \
--assign-kubelet-identity $MANAGED_IDENTITY_RESOURCE

# Set the context of your new Kubernetes cluster
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME