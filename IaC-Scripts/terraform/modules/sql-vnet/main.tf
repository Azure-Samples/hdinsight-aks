# Allows you to manage rules for allowing traffic between an Azure SQL server and a subnet of a virtual network.
resource "azurerm_mssql_firewall_rule" "metastore_server_rule" {
  count            = length(var.sql_server_id)>0 ? 1 : 0
  name             = "AllowAzureServices"
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
  server_id        = var.sql_server_id
}

resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  count     = length(var.sql_server_id)>0 && length(var.subnet_id)>0 ? 1 : 0
  name      = "sql-vnet-rule"
  server_id = var.sql_server_id
  subnet_id = var.subnet_id
}