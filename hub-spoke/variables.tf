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

variable "tgw_route_tables" {
  type    = list(string)
  default = []
}

variable "tgw_attachments" {
  type    = list(string)
  default = []
}
