### -------------------------------------------------------------------------------------------- ###
### GENERAL
### -------------------------------------------------------------------------------------------- ###

variable "aws_profile" {
  type = map(string)
}

variable "credentials_file" {
  type = string
}

variable "self_public_ip" {
  type    = string
  default = ""
}

variable "priv_key_path" {
  type    = string
  default = ""
}

### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

variable "east_hub_vpc_cidrs" {
  type = map(string)
  default = {
    vpc1 = "10.200.0.0/16"
  }
}

variable "east_spke_vpc_cidrs" {
  type = map(string)
  default = {
    vpc2 = "10.201.0.0/16",
    vpc3 = "10.202.0.0/16",
    vpc4 = "10.203.0.0/16"
  }
}

variable "east_hub_names" {
  type = map(string)
  default = {
    vpc1 = "Hub"
  }
}

variable "east_spoke_names" {
  type = map(string)
  default = {
    vpc2 = "Spoke-1",
    vpc3 = "Spoke-2",
    vpc4 = "Spoke-3"
  }
}

### -------------------------------------------------------------------------------------------- ###
### S3
### -------------------------------------------------------------------------------------------- ###

variable "bucket_name" {
  type    = string
  default = ""
}
