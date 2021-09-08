variable "instance_hostnames" {
  type    = list(string)
  default = []
}

variable "get_amzn_ami" {
  type    = bool
  default = true
}

variable "get_ubuntu_ami" {
  type    = bool
  default = false
}

variable "key_name" {
  type    = string
  default = ""
}

variable "priv_key_path" {
  type    = string
  default = ""
}
