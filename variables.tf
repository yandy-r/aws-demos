variable "self_public_ip" {
  type = string
}

variable "priv_ssh_key_path" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "domain.local"
}

variable "hostnames" {
  type    = list(string)
  default = ["central-bastion", "central-private", "spoke-1", "spoke-2", "spoke-3"]
}
variable "create_flow_logs" {
  default = true
}

variable "aws_profile" {
  type = map(string)
}

variable "owner" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "credentials_file" {
  type = string
}

variable "create_vpc_endpoint" {
  type    = bool
  default = true
}
