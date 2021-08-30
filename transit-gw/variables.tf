variable "self_public_ip" {
  type = string
}

variable "priv_ssh_key_path" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "hostnames" {
  type = list(string)
}

variable "rfc1918" {
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "create_flow_logs" {
  type    = bool
  default = true
}

variable "create_vpc_endpoint" {
  type    = bool
  default = true
}

variable "bucket_name" {
  type = string
}
