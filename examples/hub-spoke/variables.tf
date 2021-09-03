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

variable "vpc_cidrs" {
  type = any
  default = {
    east = {
      hub1   = "10.200.0.0/16"
      spoke1 = "10.201.0.0/16"
      spoke2 = "10.202.0.0/16"
      spoke3 = "10.203.0.0/16"
    }
  }
}

variable "bucket_name" {
  type    = string
  default = ""
}
