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

variable "route53_zone" {
  type    = any
  default = {}
}

variable "route53_zone_association" {
  type    = any
  default = {}
}

variable "route53_record" {
  type    = any
  default = {}
}
