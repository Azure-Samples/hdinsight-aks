# Terraform Scripts

- [Example tfvars file](./terraform/conf/example.tfvars)
- Modules
   - [resource-group](./terraform/modules/resource-group/main.tf)
   - [network](./terraform/modules/network/main.tf)
   - [cluster-pool](./terraform/modules/cluster-pool/main.tf)

# Running Example

Terraform supports a number of different methods for [authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs). In this example we are using Authenticating using [managed identities](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/managed_service_identity). You can make necessary changes based on your organization policy.

- `terraform init` - to initialize the terraform
- `terraform plan -var-file="conf/example.tfvars"` - creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure
- `terraform apply -var-file="conf/example.tfvars"`- executes the actions proposed in a Terraform plan.
- `terraform apply -var-file="conf/example.tfvars"` - It is a convenient way to destroy all remote objects managed by a particular Terraform configuration.
