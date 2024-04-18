data "azurerm_client_config" "current" {}

# HDI on AKS support "Use SQL authentication" only

data "azurerm_mssql_server" "hdi_on_aks_sql_data" {
  count               = !var.create_sql_server_flag && length(var.sql_server_name)>0 ? 1 : 0
  name                = var.sql_server_name
  resource_group_name = var.rg_name
}

resource "random_password" "password" {
  count       = var.create_sql_server_flag ? 1 : 0
  length      = 12
  special     = true
  min_upper   = 3
  min_lower   = 3
  min_special = 3
  min_numeric = 3
}

# SQL Database Server is created with Authentication method as Use SQL authentication
# it does not support  Microsoft Entra-only authentication
resource "azurerm_mssql_server" "hdi_on_aks_sql" {
  count                        = var.create_sql_server_flag ? 1 : 0
  name                         = var.sql_server_name
  resource_group_name          = var.rg_name
  location                     = var.location_name
  version                      = "12.0"
  tags                         = var.tags
  administrator_login          = var.sql_server_admin_user_name
  administrator_login_password = random_password.password[0].result
}

locals {
  sql_server_id   = var.create_sql_server_flag? azurerm_mssql_server.hdi_on_aks_sql[0].id : data.azurerm_mssql_server.hdi_on_aks_sql_data[0].id
  sql_server_name = var.create_sql_server_flag? azurerm_mssql_server.hdi_on_aks_sql[0].name : data.azurerm_mssql_server.hdi_on_aks_sql_data[0].name
}

resource "azurerm_key_vault_secret" "hdi_kv_sqldb_secret" {
  count        = var.create_sql_server_flag ? 1 : 0
  name         = "sqlhditerraform"
  value        = azurerm_mssql_server.hdi_on_aks_sql[0].administrator_login_password
  key_vault_id = var.kv_id
}
