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

variable "ssh_key" {
  type    = any
  default = {}
}

variable "hostnames" {
  type    = list(string)
  default = ["test"]
}

variable "network_interfaces" {
  type    = any
  default = {}
}

variable "aws_instances" {
  type    = any
  default = {}
}
