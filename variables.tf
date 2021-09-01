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
    Hub = "10.200.0.0/16"
  }
}

variable "east_spke_vpc_cidrs" {
  type = map(string)
  default = {
    Spoke1 = "10.201.0.0/16",
    Spoke2 = "10.202.0.0/16",
    Spoke3 = "10.203.0.0/16"
  }
}

variable "east_hub_names" {
  type = map(string)
  default = {
    Hub = "Hub"
  }
}

variable "east_spoke_names" {
  type = map(string)
  default = {
    Spoke1 = "Spoke-1",
    Spoke2 = "Spoke-2",
    Spoke3 = "Spoke-3"
  }
}

### -------------------------------------------------------------------------------------------- ###
### S3
### -------------------------------------------------------------------------------------------- ###

variable "bucket_name" {
  type    = string
  default = ""
}
