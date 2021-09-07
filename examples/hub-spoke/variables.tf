### -------------------------------------------------------------------------------------------- ###
### GENERAL
### -------------------------------------------------------------------------------------------- ###

variable "key_name" {
  type    = string
  default = "aws-test-key"
}

variable "aws_profile" {
  type = map(string)
}

variable "credentials_file" {
  type = string
}

variable "lab_public_ip" {
  type    = string
  default = ""
}

variable "lab_local_cidr" {
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

variable "cidr_blocks" {
  type = any
  default = {
    east = {
      hub1   = "10.200.0.0/16"
      spoke1 = "10.201.0.0/16"
      spoke2 = "10.202.0.0/16"
      spoke3 = "10.203.0.0/16"
    }
    west = {
      hub1   = "10.220.0.0/16"
      spoke1 = "10.221.0.0/16"
      spoke2 = "10.222.0.0/16"
      spoke3 = "10.223.0.0/16"
    }
  }
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "tunnel1_preshared_key" {
  type    = string
  default = ""
}

variable "tunnel2_preshared_key" {
  type    = string
  default = ""
}
