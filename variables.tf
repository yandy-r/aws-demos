variable "self_public_ip" {
  type = string
}

variable "priv_ssh_key_path" {
  type = string
}

variable "domain_name" {
  default = "domain.local"
}

variable "hostnames" {
  default = ["central-bastion", "central-private", "spoke-1", "spoke-2", "spoke-3"]
}

variable "rfc1918" {
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "create_flow_logs" {
  default = true
}

variable "aws_profile" {
  type = string
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
