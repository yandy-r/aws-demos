variable "name" {
  type        = string
  description = "Name used for all resources in module"
  default     = "0"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "transit_gateway" {
  type    = any
  default = {}
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

variable "transit_gateway_routes" {
  type    = any
  default = []
}

variable "vpc_routes" {
  type    = any
  default = []
}
