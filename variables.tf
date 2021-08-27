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
  default = ["ec2-1a-ssh-bastion", "ec2-1b", "ec2-2", "ec2-3"]
}
