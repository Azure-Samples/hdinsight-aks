terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.83.0"
    }
  }
}

provider "azapi" {

}

provider "azurerm" {
  features {
    resource_group {
      # keep false if you want to delete resource group managed by terraform, this will delete any resources
      # created outside of terraform state
      prevent_deletion_if_contains_resources = false
    }
  }
}