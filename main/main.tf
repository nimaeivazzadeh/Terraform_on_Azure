provider "azurerm" {
  version = "2.2.0"
  features {}
}

resource "azurerm_resource_group" "web_server_rg" {
  name     = var.rg
  location = var.location
}





