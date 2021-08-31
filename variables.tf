variable "east_vpc_cidrs" {
  type = list(string)
  default = [
    "10.200.0.0/16",
    "10.201.0.0/16",
    "10.202.0.0/16",
    "10.203.0.0/16"
  ]
}

variable "east_ec2_hostnames" {
  type = list(string)
  default = [
    "hub-e-bastion",
    "hub-e-private",
    "spoke-e-1",
    "spoke-e-2",
    "spoke-e-3"
  ]
}

variable "west_ec2_hostnames" {
  type = list(string)
  default = [
    "hub-w-bastion",
    "hub-w-private",
    "spoke-w-1",
    "spoke-w-2",
    "spoke-w-3"
  ]
}

variable "west_vpc_cidrs" {
  type = list(string)
  default = [
    "10.220.0.0/16",
    "10.221.0.0/16",
    "10.222.0.0/16",
    "10.223.0.0/16"
  ]
}

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
