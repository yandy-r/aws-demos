variable "name" {
  type        = string
  description = "Name used for all resources in module"
  default     = "0"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "tgw_tags" {
  type    = map(string)
  default = {}
}

variable "create_tgw" {
  type    = bool
  default = true
}

variable "amazon_side_asn" {
  type    = string
  default = "64512"
}

variable "auto_accept_shared_attachments" {
  type    = string
  default = "disable"
}

variable "default_route_table_association" {
  type    = string
  default = "disable"
}

variable "default_route_table_propagation" {
  type    = string
  default = "disable"
}

variable "dns_support" {
  type    = string
  default = "enable"
}

variable "vpn_ecmp_support" {
  type    = string
  default = "enable"
}

variable "vpc_attachments" {
  type    = any
  default = {}
}

variable "route_tables" {
  type    = any
  default = {}
}

variable "route_table_associations" {
  type    = any
  default = {}
}

variable "route_table_propagations" {
  type    = any
  default = {}
}

variable "tgw_routes" {
  type    = any
  default = {}
}
