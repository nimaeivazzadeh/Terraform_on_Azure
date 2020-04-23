variable "region" {
    type    = string
    default = "Washington"
}
variable "web_server_location" {
    type    = string
    default = "West US 2"
}

variable "resource_prefix" {
    type    = string
    default = "web-server"
}

variable "web_server_address_space" {
    type    = string
    default = "1.0.0.0/22"
}

variable "web_server_address_prefix" {
    type    = string
    default = "1.0.1.0/24"
 }

 variable "web_server_name" {
    type    = string
    default = "web"
 }

 variable "environment" {
    type    = string
    default = "Production"
 }

 variable "web_server_count" {
    type    = number
    default = 2
 }

 variable "web_server_subnets" {
    type    = map
    default = {
        web-server           = "1.0.1.0/24"
        AzureBastationSubnet = "1.0.2.0/24"
    }
 }