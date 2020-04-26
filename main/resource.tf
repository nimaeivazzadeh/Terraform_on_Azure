resource "azurerm_resource_group" "web_server_region" {
  name     = var.region
  location = var.web_server_location

  tags = {
    environment  = local.build_environment
    build_version = var.terraform_script_version
  }
}

resource "azurerm_virtual_network" "web_server_vnet"  {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_region.name
  address_space       = [var.web_server_address_space]
  
}

# resource "azurerm_subnet" "web_server_subnet" {
#   name                 = "${var.resource_prefix}-subnet"
#   resource_group_name  = azurerm_resource_group.web_server_region.name
#   virtual_network_name = azurerm_virtual_network.web_server_vnet.name
#   address_prefix       = var.web_server_address_prefix
# }

resource "azurerm_subnet" "web_server_subnet" {
  for_each = var.web_server_subnets

    name                 = each.key
    resource_group_name  = azurerm_resource_group.web_server_region.name
    virtual_network_name = azurerm_virtual_network.web_server_vnet.name
    address_prefix       = each.value
  }


# resource "azurerm_network_interface" "web_server_nic" {     # we are going to make an auto scale set. therefore we do not need to have this. 
#   name                 = "${var.web_server_name}-${format("%02d", count.index)}-nic"
#   location             =  var.web_server_location
#   resource_group_name  =  azurerm_resource_group.web_server_region.name
#   count                =  var.web_server_count

#   ip_configuration {
#     name               = "${var.web_server_name}-ip"
#     subnet_id          = azurerm_subnet.web_server_subnet["web-server"].id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = count.index == 0 ? azurerm_public_ip.web_server_public_ip.id : null   # This associates network interface with public ip address resource.
#   }
# }


resource "azurerm_public_ip" "web_server_lb_public_ip" {
  name                 = "${var.resource_prefix}-public-ip"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_region.name
  allocation_method    = var.environment == "Production" ? "Static" : "Dynamic"   # a conditional statement.
}

resource "azurerm_lb" "web_server_lb" {    # This resource make up a load balance resouce with associated public IP address. 
  name                 = "${var.resource_prefix}-lb"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_region.name

  frontend_ip_configuration {
    name                 = "${var.resource_prefix}-lb-frontend_ip"
    public_ip_address_id = azurerm_public_ip.web_server_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_server_lb_backend_pool" {
  name                = "${var.resource_prefix}-backend_pool"
  resource_group_name = azurerm_resource_group.web_server_region.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
}

resource "azurerm_lb_probe" "web_server_lb_http_probe" {
  name                = "${var.resource_prefix}-lb-http-probe"
  resource_group_name = azurerm_resource_group.web_server_region.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
  protocol            = "TCP"
  port                = "80"
}

resource "azurerm_lb_rule" "web_server_lb_http_rule" {
  name                = "${var.resource_prefix}-lb-http-rule"
  resource_group_name = azurerm_resource_group.web_server_region.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
  protocol            = "TCP"
  frontend_port       = "80"
  backend_port        = "80"
  frontend_ip_configuration_name = "${var.resource_prefix}-lb-frontend_ip"
  probe_id            = azurerm_lb_probe.web_server_lb_http_probe.id      # To link the rule resource to the probe.
  backend_address_pool_id  = azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id  # To link backend address pool id to this rule.
}


resource "azurerm_network_security_group" "web_server_nsg" {
  name                     = "${var.resource_prefix}-nsg"
  location                 = var.web_server_location
  resource_group_name      = azurerm_resource_group.web_server_region.name
  # count = var.environment   == "Production" ? 0 : 1   # To controll your resources.

  security_rule {
    name               = "RDP"
    priority           = 100
    direction          = "Inbound"
    access             = "Allow"
    protocol           = "TCP"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 }

 resource "azurerm_network_security_group" "web_server_nsg_http" {
  name                     = "${var.resource_prefix}-nsg"
  location                 = var.web_server_location
  resource_group_name      = azurerm_resource_group.web_server_region.name
  # count = var.environment   == "Production" ? 0 : 1   # To controll your resources.

  security_rule {
    name               = "HTTP"
    priority           = 110
    direction          = "Inbound"
    access             = "Allow"
    protocol           = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 }

 resource "azurerm_subnet_network_security_group_association" "web_server_sag" {  # to link security group to the network interface. 
   subnet_id                     = azurerm_subnet.web_server_subnet["web-server"].id
   network_security_group_id     = azurerm_network_security_group.web_server_nsg.id
 }

resource "azurerm_virtual_machine_scale_set" "web_server" {
  name                  = "${var.resource_prefix}-scale-set"
  resource_group_name   = azurerm_resource_group.web_server_region.name
  location              = var.web_server_location
  upgrade_policy_mode   = "manual"

  sku {
    name     = "Standard_F2s_v2"
    tier     = "Standard"
    capacity = var.web_server_count
  }

  os_profile {
    computer_name_prefix = local.web_server_name
    admin_username       = "webserver"
    admin_password       = "P@ssw0rd1234"
  }

  storage_profile_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile_windows_config {
    provision_vm_agent = true
  }

  network_profile {
    name    = "web_server_network_profile"
    primary = true

    ip_configuration {
      name                                   = local.web_server_name
      primary                                = true
      subnet_id                              = azurerm_subnet.web_server_subnet["web-server"].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id]
    }
  }
}