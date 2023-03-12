# ----- Parameters ------

# The subscription ID where you want to install Superset
SUBSCRIPTION=
# Superset cluster name (visible only to you)
CLUSTER_NAME=trinosuperset 
# Resource group containing the Azure Kubernetes service
RESOURCE_GROUP_NAME=trinosuperset 
# The region to deploy Superset (ideally same region as Trino): to list regions: az account list-locations REGION=westus3 
# The resource path of your managed identity. To get this resource path:
#   1. Go to the Azure Portal and find your user assigned managed identity
#   2. Select JSON View on the top right
#   3. Copy the Resource ID value.
MANAGED_IDENTITY_RESOURCE=