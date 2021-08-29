variable "self_public_ip" {
}

variable "priv_ssh_key_path" {
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
