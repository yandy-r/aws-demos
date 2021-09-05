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
  default = []
}

variable "create_internet_gateway" {
  type    = bool
  default = false
}

variable "internet_gateway" {
  type    = any
  default = []
}

variable "nat_gateway" {
  type    = any
  default = []
}

variable "azs" {
  type    = list(string)
  default = []
}

variable "public_subnets" {
  type    = any
  default = []
}

variable "public_route_table" {
  type    = any
  default = []
}

variable "private_subnets" {
  type    = any
  default = []
}

variable "private_route_table" {
  type    = any
  default = []
}

variable "intra_subnets" {
  type    = any
  default = []
}

variable "intra_route_table" {
  type    = any
  default = []
}

variable "routes" {
  type    = any
  default = {}
}

variable "vpc_endpoints" {
  type    = any
  default = []
}

variable "security_groups" {
  type    = any
  default = []
}
