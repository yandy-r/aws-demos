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

variable "vpc_cidr" {
  type    = string
  default = ""
}

variable "vpc_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "instance_tenancy" {
  type    = string
  default = "default"
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_classiclink" {
  type    = bool
  default = false
}

variable "enable_classiclink_dns_support" {
  type    = bool
  default = false
}

variable "assign_generated_ipv6_cidr_block" {
  type    = bool
  default = false
}

variable "create_igw" {
  type    = bool
  default = true
}

variable "igw_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "public_subnet_tags" {
  type        = map(string)
  description = "Tags applied and merged with tags variable to VPC"
  default     = {}
}

variable "map_public_ip_on_launch" {
  type    = bool
  default = true
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
