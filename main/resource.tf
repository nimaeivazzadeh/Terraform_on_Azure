resource "azurerm_resource_group" "web_server_region" {
  name     = var.region
  location = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet"  {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_region.name
  address_space       = [var.web_server_address_space]
  
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.web_server_region.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_address_prefix

}

resource "azurerm_network_interface" "web_server_nic" { 
  name                 = "${var.web_server_name}-nic"
  location             =  var.web_server_location
  resource_group_name  =  azurerm_resource_group.web_server_region.name

  ip_configuration {
    name               = "${var.web_server_name}-ip"
    subnet_id          = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

}


resource "azurerm_public_ip" "web_server_public_ip" {
  name                 = "${var.resource_prefix}-public-ip"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_region.name
  allocation_method    = var.environment == "Production" ? "Static" : "Dynamic"   # a conditional statement.
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                 = "${var.resource_prefix}-nsg"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_region.name

  security_rule {
    name               = "Inbound"
    priority           = 100
    direction          = "Inbound"
    access             = "Allow"
    protocol           = "TCP"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   tags ={
     environment = "Production"
   }
 }

 resource "azurerm_network_interface_security_group_association" "web_server_nsg_association" {  # to link security group to the network interface. 
   network_interface_id          = azurerm_network_interface.web_server_nic.id
   network_security_group_id     = azurerm_network_security_group.web_server_nsg.id

 }

