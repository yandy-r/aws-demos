### -------------------------------------------------------------------------------------------- ###
### EAST EC2
### -------------------------------------------------------------------------------------------- ###

module "east_ec2" {
  source    = "../../modules/ec2"
  providers = { aws = aws.us_east_1 }
  name      = "east-ec2"

  ssh_key = {
    test_key = {
      key_name   = var.key_name
      public_key = module.ssh_key.ssh_public_key
    }
  }

  network_interfaces = {
    hub_public1 = {
      source_dest_check = true
      subnet_id         = module.east_hub.public_subnet_ids[0]
      private_ips       = [cidrhost(module.east_hub.public_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_hub.security_group_ids["public1"]]
      description       = "Bastion 1 Public Interface 1"
      tags              = { Purpose = "Bastion 1 Public Interface" }
    }
    hub_private1 = {
      source_dest_check = true
      subnet_id         = module.east_hub.private_subnet_ids[0]
      private_ips       = [cidrhost(module.east_hub.private_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_hub.security_group_ids["private1"]]
      description       = "Hub 1 Private Interface 1"
    }
    spoke1 = {
      source_dest_check = true
      subnet_id         = module.east_spoke1.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.east_spoke1.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_spoke1.security_group_ids["intra1"]]
      description       = "Spoke 1 Intra Interface 1"
    }
    spoke2 = {
      source_dest_check = true
      subnet_id         = module.east_spoke2.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.east_spoke2.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_spoke2.security_group_ids["intra1"]]
      description       = "Spoke 2 Intra Interface 1"
    }
    spoke3 = {
      source_dest_check = true
      subnet_id         = module.east_spoke3.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.east_spoke3.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_spoke3.security_group_ids["intra1"]]
      description       = "Spoke 3 Intra Interface 1"
    }
  }

  aws_instances = {
    hub_public1 = {
      key_name         = var.key_name
      ami              = local.east_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.cloud_config[0]
      network_interface = [{
        network_interface_id = module.east_ec2.network_interface_ids["hub_public1"]
        device_index         = 0
      }]
    }
    hub_private1 = {
      key_name         = var.key_name
      ami              = local.east_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.cloud_config[1]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke1 = {
      key_name         = var.key_name
      ami              = local.east_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.cloud_config[2]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke2 = {
      key_name         = var.key_name
      ami              = local.east_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.cloud_config[3]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke3 = {
      key_name         = var.key_name
      ami              = local.east_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.cloud_config[4]
      network_interface = [{
        device_index = 0
      }]
    }
  }
}

### -------------------------------------------------------------------------------------------- ###
### WEST EC2
### -------------------------------------------------------------------------------------------- ###

module "west_ec2" {
  source    = "../../modules/ec2"
  providers = { aws = aws.us_west_2 }
  name      = "west-ec2"

  ssh_key = {
    test_key = {
      key_name   = var.key_name
      public_key = module.ssh_key.ssh_public_key
    }
  }

  network_interfaces = {
    hub_public1 = {
      source_dest_check = true
      subnet_id         = module.west_hub.public_subnet_ids[0]
      private_ips       = [cidrhost(module.west_hub.public_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_hub.security_group_ids["public1"]]
      description       = "Bastion 1 Public Interface 1"
      tags              = { Purpose = "Bastion 1 Public Interface" }
    }
    hub_private1 = {
      source_dest_check = true
      subnet_id         = module.west_hub.private_subnet_ids[0]
      private_ips       = [cidrhost(module.west_hub.private_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_hub.security_group_ids["private1"]]
      description       = "Hub 1 Private Interface 1"
    }
    spoke1 = {
      source_dest_check = true
      subnet_id         = module.west_spoke1.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.west_spoke1.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_spoke1.security_group_ids["intra1"]]
      description       = "Spoke 1 Intra Interface 1"
    }
    spoke2 = {
      source_dest_check = true
      subnet_id         = module.west_spoke2.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.west_spoke2.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_spoke2.security_group_ids["intra1"]]
      description       = "Spoke 2 Intra Interface 1"
    }
    spoke3 = {
      source_dest_check = true
      subnet_id         = module.west_spoke3.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.west_spoke3.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_spoke3.security_group_ids["intra1"]]
      description       = "Spoke 3 Intra Interface 1"
    }
  }

  aws_instances = {
    hub_public1 = {
      key_name         = var.key_name
      ami              = local.west_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.cloud_config[0]
      network_interface = [{
        network_interface_id = module.west_ec2.network_interface_ids["hub_public1"]
        device_index         = 0
      }]
    }
    hub_private1 = {
      key_name         = var.key_name
      ami              = local.west_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.cloud_config[1]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke1 = {
      key_name         = var.key_name
      ami              = local.west_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.cloud_config[2]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke2 = {
      key_name         = var.key_name
      ami              = local.west_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.cloud_config[3]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke3 = {
      key_name         = var.key_name
      ami              = local.west_data.ubuntu_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.cloud_config[4]
      network_interface = [{
        device_index = 0
      }]
    }
  }
}
