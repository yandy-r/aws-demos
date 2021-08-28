variable "self_public_ip" {
}

variable "priv_ssh_key_path" {
}

variable "domain_name" {
  default = "domain.local"
}

variable "hostnames" {
  default = ["core-bastion", "core-private", "spoke-1", "spoke-2", "spoke-3"]
}
