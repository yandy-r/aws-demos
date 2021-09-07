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
  default = {}
}

variable "security_group_rules" {
  type    = any
  default = []
}

variable "flow_logs" {
  type    = any
  default = {}
}

variable "cloudwatch_log_groups" {
  type    = any
  default = {}
}

variable "flow_logs_role_policy" {
  type    = any
  default = {}
}

variable "flow_logs_role" {
  type    = any
  default = {}
}

variable "customer_gateway" {
  type    = any
  default = {}
}

variable "vpn_connection" {
  type    = any
  default = {}
}
