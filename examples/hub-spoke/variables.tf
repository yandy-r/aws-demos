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
    hub1 = "10.200.0.0/16"
  }
}

variable "east_spke_vpc_cidrs" {
  type = map(string)
  default = {
    spoke1 = "10.201.0.0/16",
    spoke2 = "10.202.0.0/16",
    spoke3 = "10.203.0.0/16"
  }
}

variable "east_hub_names" {
  type = map(string)
  default = {
    hub1 = "hub1"
  }
}

variable "east_spoke_names" {
  type = map(string)
  default = {
    spoke1 = "spoke-1",
    spoke2 = "spoke-2",
    spoke3 = "spoke-3"
  }
}

### -------------------------------------------------------------------------------------------- ###
### S3
### -------------------------------------------------------------------------------------------- ###

variable "bucket_name" {
  type    = string
  default = ""
}
