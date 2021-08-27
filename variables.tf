variable "self_public_ip" {
}

variable "priv_ssh_key_path" {
}

variable "pub_ssh_key_path" {
}

variable "ssh_key_name" {}

variable "domain_name" {
  default = "domain.local"
}

variable "hostnames" {
  default = ["core-1a-ssh-bastion", "core-1b", "spoke-1", "spoke-2", "spoke-3"]
}
