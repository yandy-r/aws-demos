### -------------------------------------------------------------------------------------------- ###
### UNIVERSAL SSH KEY
### -------------------------------------------------------------------------------------------- ###

module "ssh_key" {
  source        = "../../modules/ssh-key"
  key_name      = var.key_name
  priv_key_path = var.priv_key_path
}

### -------------------------------------------------------------------------------------------- ###
### EAST DATA
### -------------------------------------------------------------------------------------------- ###

module "east_data" {
  source         = "../../modules/data"
  providers      = { aws = aws.us_east_1 }
  get_ubuntu_ami = true
  key_name       = var.key_name
  priv_key_path  = var.priv_key_path
  instance_hostnames = [
    "hub_public1",
    "hub_private1",
    "spoke1",
    "spoke2",
    "spoke3",
  ]

  depends_on = [
    module.ssh_key
  ]
}

locals {
  east_data = {
    s3_endpoint_policy = module.east_data.s3_endpoint_policy
    ubuntu_ami         = module.east_data.ubuntu_ami
    cloud_config       = module.east_data.cloud_config
    ubuntu_ami         = module.east_data.ubuntu_ami
  }
}

### -------------------------------------------------------------------------------------------- ###
### WEST DATA
### -------------------------------------------------------------------------------------------- ###

module "west_data" {
  source         = "../../modules/data"
  providers      = { aws = aws.us_west_2 }
  get_ubuntu_ami = true
  key_name       = var.key_name
  priv_key_path  = var.priv_key_path
  instance_hostnames = [
    "hub_public1",
    "hub_private1",
    "spoke1",
    "spoke2",
    "spoke3",
  ]

  depends_on = [
    module.ssh_key
  ]
}

locals {
  west_data = {
    s3_endpoint_policy = module.west_data.s3_endpoint_policy
    ubuntu_ami         = module.west_data.ubuntu_ami
    cloud_config       = module.west_data.cloud_config
    ubuntu_ami         = module.west_data.ubuntu_ami
  }
}
