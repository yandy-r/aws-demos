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

variable "priv_key_path" {
  type    = string
  default = ""
}

variable "priv_key" {
  type    = map(string)
  default = {}
}

variable "hostnames" {
  type    = list(string)
  default = ["test"]
}

variable "key_name" {
  type    = string
  default = ""
}

variable "network_interfaces" {
  type    = any
  default = {}
}

variable "eni_tags" {
  type    = map(string)
  default = {}
}
