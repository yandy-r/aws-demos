### --- EAST --- ###
variable "self_public_ip" {
  type = string
}

variable "priv_ssh_key_path" {
  type = string
}

variable "domain_name_east" {
  type    = string
  default = "domain.local.east"
}

variable "create_flow_logs" {
  default = true
}

variable "aws_profile" {
  type = map(string)
}

variable "credentials_file" {
  type = string
}

variable "create_vpc_endpoint" {
  type    = bool
  default = true
}

variable "bucket_name" {
  type = string
}
