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
    public_ip_address_id          = azurerm_public_ip.azurerm_public_ip.id   # This associates network interface with public ip address resource.
  }

}


resource "azurerm_public_ip" "azurerm_public_ip" {
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

resource "azurerm_windows_virtual_machine" "web_server" {
  name                = var.web_server_name
  resource_group_name = azurerm_resource_group.web_server_region.name
  location            = var.web_server_location
  size                = "Standard_B1s"
  admin_username      = "webserver"
  admin_password      = "P@ssw0rd123"
  network_interface_ids = [
    azurerm_network_interface.web_server_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }
}