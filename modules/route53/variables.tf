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

variable "security_groups" {
  type    = any
  default = {}
}

variable "security_group_rules" {
  type    = any
  default = {}
}

variable "resolver_endpoint" {
  type    = any
  default = {}
}

variable "resolver_rule" {
  type    = any
  default = {}
}

variable "resolver_rule_association" {
  type    = any
  default = []
}
