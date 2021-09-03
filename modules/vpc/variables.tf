### -------------------------------------------------------------------------------------------- ###
### S3
### -------------------------------------------------------------------------------------------- ###

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

variable "vpc" {
  type    = any
  default = {}
}

variable "create_inet_gw" {
  type    = bool
  default = false
}

variable "inet_gw" {
  type    = any
  default = {}
}

variable "azs" {
  type    = list(string)
  default = []
}

variable "public_subnets" {
  type    = any
  default = {}
}

variable "public_route_table" {
  type    = any
  default = {}
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "intra_subnets" {
  type    = list(string)
  default = []
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "intra_subnet_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "nat_gateway_count" {
  type    = number
  default = 1
}

variable "nat_eip_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "nat_gateway_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "public_route_table_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "private_route_table_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "intra_route_table_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "vpc_endpoints" {
  type    = any
  default = {}
}
