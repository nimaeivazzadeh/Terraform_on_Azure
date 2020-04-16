variable "region" {
    type    = string
    default = "Oslo"
}
variable "web_server_location" {
    type    = string
    default = "Norway East"
}

variable "resource_prefix" {
    type    = string
    default = "web-server"
}

variable "web_server_address_space" {
    type    = string
    default = "1.0.0.0/22"
}