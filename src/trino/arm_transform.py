from multiprocessing import pool
from pathlib import Path
import sys
import json

if len(sys.argv) != 2:
print("Please provide arm json file path as input.")
print("Usage:")
print("arm_transform.py [template.json]")
sys.exit()

# Open file and parse json
filename = sys.argv[1]
filename_stem = Path(filename).stem
output_filename = filename_stem + "-modified.json"

f = open(filename, "r")
json_arm = json.load(f)
f.close()

# Extract fields from template json
fqdn = json_arm["properties"]["clusterProfile"]["connectivityProfile"]["web"]["fqdn"]
fqdn_parts = fqdn.split('.')
pool_name = fqdn_parts[1]
cluster_name = fqdn_parts[0]
region = json_arm["location"]

id = json_arm["id"]
id_parts = id.split('/')
subscription = id_parts[2]
resource_group = id_parts[4]

# Remove elements that must not appear in the ARM template
del json_arm["id"]
del json_arm["systemData"]
del json_arm["properties"]["deploymentId"]
del json_arm["properties"]["provisioningState"]
json_arm["location"] = region
json_arm["apiversion"] = "2021-09-15-preview"
json_arm["properties"]["clusterProfile"]["connectivityProfile"]["web"]["fqdn"] = cluster_name + "." + pool_name + "." + region + ".projecthilo.net"
json_arm["name"] = pool_name + "/" + cluster_name

# Wrap the template in the expected ARM schema
json_new_root = {}
json_new_root["$schema"] = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
json_new_root["contentVersion"] = "1.0.0.0"
json_new_root["parameters"] = {}
json_new_root["resources"] = [json_arm]

# Write the modified template
f = open(output_filename, "w")
json.dump(json_new_root, f)
f.close()

print("Written modified template to " + output_filename)
print()
print("To redeploy, execute the following Azure CLI command:")
print("az deployment group create --subscription " + subscription + " --resource-group " + resource_group + " --template-file " + output_filename)