
variable "name" {
  type        = string
  description = "Name used for all resources in module"
  default     = "0"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in module"
  default     = {}
}

variable "tgw_tags" {
  type        = map(string)
  description = "Tags applied to all resources in module"
  default     = {}
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

variable "vpc_ids" {
  type    = list(string)
  default = []
}

variable "subnet_ids" {
  type    = list(list(string))
  default = []
}

variable "create_vpc_attach" {
  type    = bool
  default = false
}

variable "create_custom_attach" {
  type    = bool
  default = false
}

variable "transit_gateway_default_route_table_association" {
  type    = bool
  default = false
}

variable "transit_gateway_default_route_table_propagation" {
  type    = bool
  default = false
}

variable "custom_attach" {
  type    = list(map(string))
  default = []
}

variable "attach_tags" {
  type    = list(map(string))
  default = []
}

variable "create_route_tables" {
  type    = bool
  default = false
}

variable "num_route_tables" {
  type    = number
  default = 0
}

variable "route_table_tags" {
  type    = list(map(string))
  default = []
}

variable "route_table_associatons" {
  type    = list(map(string))
  default = []
}

variable "route_table_propagations" {
  type    = map(map(string))
  default = {}
}
