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
  source        = "./data"
  providers     = { aws = aws.us_east_1 }
  get_amzn_ami  = true
  key_name      = var.key_name
  priv_key_path = var.priv_key_path
  instance_hostnames = [
    "hub_bastion1",
    "hub_private1",
    "spoke1_intra1",
    "spoke2_intra1",
    "spoke3_intra1",
  ]

  depends_on = [
    module.ssh_key
  ]
}

locals {
  east_data = {
    s3_endpoint_policy  = module.east_data.s3_endpoint_policy
    amzn_ami            = module.east_data.amzn_ami
    amzn_cloud_config   = module.east_data.amzn_cloud_config
    ubuntu_ami          = module.east_data.ubuntu_ami
    ubuntu_cloud_config = module.east_data.ubuntu_cloud_config
  }
}

### -------------------------------------------------------------------------------------------- ###
### US-EAST-1 INFRASTRUCTURE
### -------------------------------------------------------------------------------------------- ###

module "east_hub" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east-hub"

  vpc = [{
    cidr_block                       = var.cidr_blocks.east["hub1"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
    }
  ]

  public_subnets = [
    {
      name                    = "public-1"
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 0)
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
    },
    {
      name                    = "public-2"
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 1)
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = true
    }
  ]

  private_subnets = [
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 64)
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
    },
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 65)
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = true
    }
  ]

  intra_subnets = [
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 128)
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
    },
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 129)
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = true
    }
  ]

  public_route_table  = [{}]
  private_route_table = [{}]
  intra_route_table   = [{}]
  internet_gateway    = [{}]
  nat_gateway         = [{}]

  vpc_endpoints = [{
    endpoint_type = "Gateway"
    service_type  = "s3"
    policy        = local.east_data.s3_endpoint_policy
    tags = {
      Name = "east-hub-s3-endpoint"
    }
  }]
  security_groups = {
    public1  = {},
    private1 = {},
    intra1   = {},
  }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.east_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.east_hub.security_group_ids["private1"]
    },
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.east_hub.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["public1"]
      security_group_id        = module.east_hub.security_group_ids["public1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["private1"]
      security_group_id        = module.east_hub.security_group_ids["private1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["intra1"]
      security_group_id        = module.east_hub.security_group_ids["intra1"]
    },
    {
      description       = "Allow ICMP from home"
      type              = "ingress"
      from_port         = -1
      to_port           = -1
      protocol          = "icmp"
      cidr_blocks       = [var.self_public_ip]
      security_group_id = module.east_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow SSH from home"
      type              = "ingress"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = [var.self_public_ip]
      security_group_id = module.east_hub.security_group_ids["public1"]
    },
    {
      description              = "Allow ALL sourced from private"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["private1"]
      security_group_id        = module.east_hub.security_group_ids["public1"]
    },
    {
      description              = "Allow ALL sourced from public"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["public1"]
      security_group_id        = module.east_hub.security_group_ids["private1"]
    },
    {
      description              = "Allow ALL sourced from intra"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["intra1"]
      security_group_id        = module.east_hub.security_group_ids["private1"]
    },
    {
      description              = "Allow ALL sourced from public"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["public1"]
      security_group_id        = module.east_hub.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from private"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_hub.security_group_ids["private1"]
      security_group_id        = module.east_hub.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from spokes to private"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_spoke1.cidr_block,
        module.east_spoke2.cidr_block,
        module.east_spoke3.cidr_block,
      ]
      security_group_id = module.east_hub.security_group_ids["private1"]
    },
    {
      description = "Allow all sourced from spokes to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_spoke1.cidr_block,
        module.east_spoke2.cidr_block,
        module.east_spoke3.cidr_block,
      ]
      security_group_id = module.east_hub.security_group_ids["intra1"]
    },
  ]
}

module "east_spoke1" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east-spoke1"

  vpc = [{
    cidr_block                       = var.cidr_blocks.east["spoke1"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
  }]

  intra_subnets = [
    {
      cidr_block        = cidrsubnet(module.east_spoke1.cidr_block, 8, 128)
      availability_zone = "us-east-1a"
    },
    {
      cidr_block        = cidrsubnet(module.east_spoke1.cidr_block, 8, 129)
      availability_zone = "us-east-1b"
    },
  ]
  intra_route_table = [{}]
  security_groups   = { intra1 = {} }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.east_spoke1.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_spoke1.security_group_ids["intra1"]
      security_group_id        = module.east_spoke1.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from hub and spoke2 to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
        module.east_spoke2.cidr_block,
      ]
      security_group_id = module.east_spoke1.security_group_ids["intra1"]
    },
  ]
}

module "east_spoke2" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east-spoke2"

  vpc = [{
    cidr_block                       = var.cidr_blocks.east["spoke2"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
  }]

  intra_subnets = [
    {
      cidr_block        = cidrsubnet(module.east_spoke2.cidr_block, 8, 128)
      availability_zone = "us-east-1c"
    },
    {
      cidr_block        = cidrsubnet(module.east_spoke2.cidr_block, 8, 129)
      availability_zone = "us-east-1d"
    },
  ]
  intra_route_table = [{}]
  security_groups   = { intra1 = {} }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.east_spoke2.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_spoke2.security_group_ids["intra1"]
      security_group_id        = module.east_spoke2.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from hub and spoke1 to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
        module.east_spoke1.cidr_block,
      ]
      security_group_id = module.east_spoke2.security_group_ids["intra1"]
    },
  ]
}

module "east_spoke3" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east-spoke3"

  vpc = [{
    cidr_block                       = var.cidr_blocks.east["spoke3"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
  }]

  intra_subnets = [
    {
      cidr_block        = cidrsubnet(module.east_spoke3.cidr_block, 8, 128)
      availability_zone = "us-east-1f"
    }
  ]
  intra_route_table = [{}]
  security_groups   = { intra1 = {} }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.east_spoke3.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.east_spoke3.security_group_ids["intra1"]
      security_group_id        = module.east_spoke3.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from hub intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
      ]
      security_group_id = module.east_spoke3.security_group_ids["intra1"]
    },
  ]
}

module "east_ec2" {
  source    = "../../modules/ec2"
  providers = { aws = aws.us_east_1 }
  name      = "east-ec2"
  key_name  = var.key_name
  priv_key  = module.ssh_key.priv_key

  network_interfaces = {
    hub_bastion1 = {
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
    spoke1_intra1 = {
      source_dest_check = true
      subnet_id         = module.east_spoke1.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.east_spoke1.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_spoke1.security_group_ids["intra1"]]
      description       = "Spoke 1 Intra Interface 1"
    }
    spoke2_intra1 = {
      source_dest_check = true
      subnet_id         = module.east_spoke2.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.east_spoke2.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_spoke2.security_group_ids["intra1"]]
      description       = "Spoke 2 Intra Interface 1"
    }
    spoke3_intra1 = {
      source_dest_check = true
      subnet_id         = module.east_spoke3.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.east_spoke3.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.east_spoke3.security_group_ids["intra1"]]
      description       = "Spoke 3 Intra Interface 1"
    }
  }

  aws_instances = {
    hub_bastion1 = {
      ami              = local.east_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.amzn_cloud_config[0]
      network_interface = [{
        network_interface_id = module.east_ec2.network_interface_ids["hub_bastion1"]
        device_index         = 0
      }]
    }
    hub_private1 = {
      ami              = local.east_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.amzn_cloud_config[1]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke1_intra1 = {
      ami              = local.east_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.amzn_cloud_config[2]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke2_intra1 = {
      ami              = local.east_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.amzn_cloud_config[3]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke3_intra1 = {
      ami              = local.east_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.east_data.amzn_cloud_config[4]
      network_interface = [{
        device_index = 0
      }]
    }
  }
}

module "east_transit_gateway" {
  source    = "../../modules/transit-gateway"
  providers = { aws = aws.us_east_1 }
  name      = "east-tgw"

  transit_gateway = [{
    dns_support                     = "enable"
    description                     = "US East Transit Gateway"
    amazon_side_asn                 = 65000
    vpn_ecmp_support                = "enable"
    auto_accept_shared_attachments  = "disable"
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    tags                            = { Purpose = "Central routing hub for the east" }
  }]

  vpc_attachments = {
    hub1 = {
      vpc_id                                          = module.east_hub.vpc_id
      subnet_ids                                      = module.east_hub.private_subnet_ids
      dns_support                                     = "enable"
      ipv6_support                                    = "disable"
      appliance_mode_support                          = "disable"
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags                                            = { Purpose = "Attachment to Hub1 VPC" }
    }
    spoke1 = {
      vpc_id     = module.east_spoke1.vpc_id
      subnet_ids = module.east_spoke1.intra_subnet_ids
    }
    spoke2 = {
      vpc_id     = module.east_spoke2.vpc_id
      subnet_ids = module.east_spoke2.intra_subnet_ids
    }
    spoke3 = {
      vpc_id     = module.east_spoke3.vpc_id
      subnet_ids = module.east_spoke3.intra_subnet_ids
    }
  }

  route_tables = {
    hubs         = {}
    spokes       = {}
    east_to_west = {}
  }

  route_table_associations = {
    hub1 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke1 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke2 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke3 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
  }

  route_table_propagations = {
    hub_to_spokes = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke_1_to_hub = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke_2_to_hub = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke_3_to_hub = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke_1_to_2 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke_2_to_1 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
  }

  transit_gateway_routes = [
    {
      destination                   = "0.0.0.0/0"
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    }
  ]

  vpc_routes = [
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_hub.public_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_hub.private_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_hub.intra_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke1.intra_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke2.intra_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke3.intra_route_table_id
    },
  ]
}

### -------------------------------------------------------------------------------------------- ###
### EAST DATA
### -------------------------------------------------------------------------------------------- ###

module "west_data" {
  source        = "./data"
  providers     = { aws = aws.us_west_2 }
  get_amzn_ami  = true
  key_name      = var.key_name
  priv_key_path = var.priv_key_path
  instance_hostnames = [
    "hub_bastion1",
    "hub_private1",
    "spoke1_intra1",
    "spoke2_intra1",
    "spoke3_intra1",
  ]

  depends_on = [
    module.ssh_key
  ]
}

locals {
  west_data = {
    s3_endpoint_policy  = module.west_data.s3_endpoint_policy
    amzn_ami            = module.west_data.amzn_ami
    amzn_cloud_config   = module.west_data.amzn_cloud_config
    ubuntu_ami          = module.west_data.ubuntu_ami
    ubuntu_cloud_config = module.west_data.ubuntu_cloud_config
  }
}

### -------------------------------------------------------------------------------------------- ###
### US-WEST-2 INFRASTRUCTURE
### -------------------------------------------------------------------------------------------- ###

module "west_hub" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_west_2 }
  name      = "west-hub"

  vpc = [{
    cidr_block                       = var.cidr_blocks.west["hub1"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
    }
  ]

  public_subnets = [
    {
      name                    = "public-1"
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 0)
      availability_zone       = "us-west-2a"
      map_public_ip_on_launch = true
    },
    {
      name                    = "public-2"
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 1)
      availability_zone       = "us-west-2b"
      map_public_ip_on_launch = true
    }
  ]

  private_subnets = [
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 64)
      availability_zone       = "us-west-2a"
      map_public_ip_on_launch = true
    },
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 65)
      availability_zone       = "us-west-2b"
      map_public_ip_on_launch = true
    }
  ]

  intra_subnets = [
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 128)
      availability_zone       = "us-west-2a"
      map_public_ip_on_launch = true
    },
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 129)
      availability_zone       = "us-west-2b"
      map_public_ip_on_launch = true
    }
  ]

  public_route_table  = [{}]
  private_route_table = [{}]
  intra_route_table   = [{}]
  internet_gateway    = [{}]
  nat_gateway         = [{}]

  vpc_endpoints = [{
    endpoint_type = "Gateway"
    service_type  = "s3"
    policy        = local.west_data.s3_endpoint_policy
    tags = {
      Name = "west-hub-s3-endpoint"
    }
  }]
  security_groups = {
    public1  = {},
    private1 = {},
    intra1   = {},
  }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.west_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.west_hub.security_group_ids["private1"]
    },
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.west_hub.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["public1"]
      security_group_id        = module.west_hub.security_group_ids["public1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["private1"]
      security_group_id        = module.west_hub.security_group_ids["private1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["intra1"]
      security_group_id        = module.west_hub.security_group_ids["intra1"]
    },
    {
      description       = "Allow ICMP from home"
      type              = "ingress"
      from_port         = -1
      to_port           = -1
      protocol          = "icmp"
      cidr_blocks       = [var.self_public_ip]
      security_group_id = module.west_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow SSH from home"
      type              = "ingress"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = [var.self_public_ip]
      security_group_id = module.west_hub.security_group_ids["public1"]
    },
    {
      description              = "Allow ALL sourced from private"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["private1"]
      security_group_id        = module.west_hub.security_group_ids["public1"]
    },
    {
      description              = "Allow ALL sourced from public"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["public1"]
      security_group_id        = module.west_hub.security_group_ids["private1"]
    },
    {
      description              = "Allow ALL sourced from intra"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["intra1"]
      security_group_id        = module.west_hub.security_group_ids["private1"]
    },
    {
      description              = "Allow ALL sourced from public"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["public1"]
      security_group_id        = module.west_hub.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from private"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_hub.security_group_ids["private1"]
      security_group_id        = module.west_hub.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from spokes to private"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_spoke1.cidr_block,
        module.west_spoke2.cidr_block,
        module.west_spoke3.cidr_block,
      ]
      security_group_id = module.west_hub.security_group_ids["private1"]
    },
    {
      description = "Allow all sourced from spokes to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_spoke1.cidr_block,
        module.west_spoke2.cidr_block,
        module.west_spoke3.cidr_block,
      ]
      security_group_id = module.west_hub.security_group_ids["intra1"]
    },
  ]
}

module "west_spoke1" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_west_2 }
  name      = "west-spoke1"

  vpc = [{
    cidr_block                       = var.cidr_blocks.west["spoke1"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
  }]

  intra_subnets = [
    {
      cidr_block        = cidrsubnet(module.west_spoke1.cidr_block, 8, 128)
      availability_zone = "us-west-2a"
    },
    {
      cidr_block        = cidrsubnet(module.west_spoke1.cidr_block, 8, 129)
      availability_zone = "us-west-2b"
    },
  ]
  intra_route_table = [{}]
  security_groups   = { intra1 = {} }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.west_spoke1.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_spoke1.security_group_ids["intra1"]
      security_group_id        = module.west_spoke1.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from hub and spoke2 to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_hub.cidr_block,
        module.west_spoke2.cidr_block,
      ]
      security_group_id = module.west_spoke1.security_group_ids["intra1"]
    },
  ]
}

module "west_spoke2" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_west_2 }
  name      = "west-spoke2"

  vpc = [{
    cidr_block                       = var.cidr_blocks.west["spoke2"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
  }]

  intra_subnets = [
    {
      cidr_block        = cidrsubnet(module.west_spoke2.cidr_block, 8, 128)
      availability_zone = "us-west-2c"
    },
    {
      cidr_block        = cidrsubnet(module.west_spoke2.cidr_block, 8, 129)
      availability_zone = "us-west-2d"
    },
  ]
  intra_route_table = [{}]
  security_groups   = { intra1 = {} }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.west_spoke2.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_spoke2.security_group_ids["intra1"]
      security_group_id        = module.west_spoke2.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from hub and spoke1 to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_hub.cidr_block,
        module.west_spoke1.cidr_block,
      ]
      security_group_id = module.west_spoke2.security_group_ids["intra1"]
    },
  ]
}

module "west_spoke3" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_west_2 }
  name      = "west-spoke3"

  vpc = [{
    cidr_block                       = var.cidr_blocks.west["spoke3"]
    instance_tenancy                 = "default"
    enable_dns_hostnames             = true
    enable_dns_support               = true
    enable_classiclink               = false
    enable_classiclink_dns_support   = false
    assign_generated_ipv6_cidr_block = false
  }]

  intra_subnets = [
    {
      cidr_block        = cidrsubnet(module.west_spoke3.cidr_block, 8, 128)
      availability_zone = "us-west-2d"
    }
  ]
  intra_route_table = [{}]
  security_groups   = { intra1 = {} }

  security_group_rules = [
    {
      description       = "Allow all out"
      type              = "egress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      security_group_id = module.west_spoke3.security_group_ids["intra1"]
    },
    {
      description              = "Allow ALL sourced from self"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.west_spoke3.security_group_ids["intra1"]
      security_group_id        = module.west_spoke3.security_group_ids["intra1"]
    },
    {
      description = "Allow all sourced from hub intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_hub.cidr_block,
      ]
      security_group_id = module.west_spoke3.security_group_ids["intra1"]
    },
  ]
}

module "west_ec2" {
  source    = "../../modules/ec2"
  providers = { aws = aws.us_west_2 }
  name      = "west-ec2"
  key_name  = var.key_name
  priv_key  = module.ssh_key.priv_key

  network_interfaces = {
    hub_bastion1 = {
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
    spoke1_intra1 = {
      source_dest_check = true
      subnet_id         = module.west_spoke1.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.west_spoke1.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_spoke1.security_group_ids["intra1"]]
      description       = "Spoke 1 Intra Interface 1"
    }
    spoke2_intra1 = {
      source_dest_check = true
      subnet_id         = module.west_spoke2.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.west_spoke2.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_spoke2.security_group_ids["intra1"]]
      description       = "Spoke 2 Intra Interface 1"
    }
    spoke3_intra1 = {
      source_dest_check = true
      subnet_id         = module.west_spoke3.intra_subnet_ids[0]
      private_ips       = [cidrhost(module.west_spoke3.intra_subnet_cidr_blocks[0], 10)]
      security_groups   = [module.west_spoke3.security_group_ids["intra1"]]
      description       = "Spoke 3 Intra Interface 1"
    }
  }

  aws_instances = {
    hub_bastion1 = {
      ami              = local.west_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.amzn_cloud_config[0]
      network_interface = [{
        network_interface_id = module.west_ec2.network_interface_ids["hub_bastion1"]
        device_index         = 0
      }]
    }
    hub_private1 = {
      ami              = local.west_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.amzn_cloud_config[1]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke1_intra1 = {
      ami              = local.west_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.amzn_cloud_config[2]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke2_intra1 = {
      ami              = local.west_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.amzn_cloud_config[3]
      network_interface = [{
        device_index = 0
      }]
    }
    spoke3_intra1 = {
      ami              = local.west_data.amzn_ami
      instance_type    = "t3.medium"
      user_data_base64 = local.west_data.amzn_cloud_config[4]
      network_interface = [{
        device_index = 0
      }]
    }
  }
}

module "west_transit_gateway" {
  source    = "../../modules/transit-gateway"
  providers = { aws = aws.us_west_2 }
  name      = "west-tgw"

  transit_gateway = [{
    dns_support                     = "enable"
    description                     = "US East Transit Gateway"
    amazon_side_asn                 = 65000
    vpn_ecmp_support                = "enable"
    auto_accept_shared_attachments  = "disable"
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    tags                            = { Purpose = "Central routing hub for the west" }
  }]

  vpc_attachments = {
    hub1 = {
      vpc_id                                          = module.west_hub.vpc_id
      subnet_ids                                      = module.west_hub.private_subnet_ids
      dns_support                                     = "enable"
      ipv6_support                                    = "disable"
      appliance_mode_support                          = "disable"
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags                                            = { Purpose = "Attachment to Hub1 VPC" }
    }
    spoke1 = {
      vpc_id     = module.west_spoke1.vpc_id
      subnet_ids = module.west_spoke1.intra_subnet_ids
    }
    spoke2 = {
      vpc_id     = module.west_spoke2.vpc_id
      subnet_ids = module.west_spoke2.intra_subnet_ids
    }
    spoke3 = {
      vpc_id     = module.west_spoke3.vpc_id
      subnet_ids = module.west_spoke3.intra_subnet_ids
    }
  }

  route_tables = {
    hubs         = {}
    spokes       = {}
    east_to_west = {}
  }

  route_table_associations = {
    hub1 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke1 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke2 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke3 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
  }

  route_table_propagations = {
    hub_to_spokes = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke_1_to_hub = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke_2_to_hub = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke_3_to_hub = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke_1_to_2 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke_2_to_1 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
  }

  transit_gateway_routes = [
    {
      destination                   = "0.0.0.0/0"
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    }
  ]

  vpc_routes = [
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_hub.public_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_hub.private_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_hub.intra_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke1.intra_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke2.intra_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke3.intra_route_table_id
    },
  ]
}

### -------------------------------------------------------------------------------------------- ###
### US-EAST-1 TO USE-WEST-2 COMMUNICATION
### -------------------------------------------------------------------------------------------- ###

# resource "aws_ec2_transit_gateway_route_table_association" "east_to_west" {
#   provider                       = aws.us_east_1
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.east_west.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
# }

# resource "aws_ec2_transit_gateway_route" "east_to_west" {
#   provider                       = aws.us_east_1
#   for_each                       = { for k, v in local.all_east_tgw_rts : k => v }
#   destination_cidr_block         = "10.220.0.0/14"
#   transit_gateway_route_table_id = each.value.id
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.east_west.id
# }

# resource "aws_ec2_transit_gateway_route" "east_peering_to_hub_vpc" {
#   provider                       = aws.us_east_1
#   destination_cidr_block         = "10.200.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
#   transit_gateway_attachment_id  = local.east_tgw_attach_id[0]
# }

# resource "aws_ec2_transit_gateway_route" "east_peering_to_spoke_1_vpc" {
#   provider                       = aws.us_east_1
#   destination_cidr_block         = "10.201.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
#   transit_gateway_attachment_id  = local.east_tgw_attach_id[1]
# }

# resource "aws_ec2_transit_gateway_route" "east_peering_to_spoke_2_vpc" {
#   provider                       = aws.us_east_1
#   destination_cidr_block         = "10.202.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
#   transit_gateway_attachment_id  = local.east_tgw_attach_id[2]
# }

# resource "aws_ec2_transit_gateway_route" "east_peering_to_spoke_3_vpc" {
#   provider                       = aws.us_east_1
#   destination_cidr_block         = "10.203.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
#   transit_gateway_attachment_id  = local.east_tgw_attach_id[3]
# }

# resource "aws_route" "east_peering_routes_private" {
#   provider               = aws.us_east_1
#   for_each               = { for k, v in local.east_private_rts : k => v }
#   route_table_id         = each.value.id
#   destination_cidr_block = "10.220.0.0/14"
#   transit_gateway_id     = local.east_tgw.id
# }

# resource "aws_route" "east_peering_routes_public" {
#   provider               = aws.us_east_1
#   for_each               = { for k, v in local.east_public_rts : k => v }
#   route_table_id         = each.value.id
#   destination_cidr_block = "10.220.0.0/14"
#   transit_gateway_id     = local.east_tgw.id
# }

# resource "aws_ec2_transit_gateway_route_table" "west_to_east" {
#   provider           = aws.us_west_2
#   transit_gateway_id = local.west_tgw.id

#   tags = {
#     Name = "WEST->EAST"
#   }
# }

# resource "aws_ec2_transit_gateway_route_table_association" "west_to_east" {
#   provider                       = aws.us_west_2
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.east_west.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
# }

# resource "aws_ec2_transit_gateway_route" "west_to_east" {
#   provider                       = aws.us_west_2
#   for_each                       = { for k, v in local.all_west_tgw_rts : k => v }
#   destination_cidr_block         = "10.200.0.0/14"
#   transit_gateway_route_table_id = each.value.id
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.east_west.id
# }

# resource "aws_ec2_transit_gateway_route" "west_peering_to_hub_vpc" {
#   provider                       = aws.us_west_2
#   destination_cidr_block         = "10.220.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
#   transit_gateway_attachment_id  = local.west_tgw_attach_id[0]
# }

# resource "aws_ec2_transit_gateway_route" "west_peering_to_spoke_1_vpc" {
#   provider                       = aws.us_west_2
#   destination_cidr_block         = "10.221.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
#   transit_gateway_attachment_id  = local.west_tgw_attach_id[1]
# }

# resource "aws_ec2_transit_gateway_route" "west_peering_to_spoke_2_vpc" {
#   provider                       = aws.us_west_2
#   destination_cidr_block         = "10.222.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
#   transit_gateway_attachment_id  = local.west_tgw_attach_id[2]
# }

# resource "aws_ec2_transit_gateway_route" "west_peering_to_spoke_3_vpc" {
#   provider                       = aws.us_west_2
#   destination_cidr_block         = "10.223.0.0/16"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
#   transit_gateway_attachment_id  = local.west_tgw_attach_id[3]
# }

# resource "aws_route" "west_peering_routes_private" {
#   provider               = aws.us_west_2
#   for_each               = { for k, v in local.west_private_rts : k => v }
#   route_table_id         = each.value.id
#   destination_cidr_block = "10.200.0.0/14"
#   transit_gateway_id     = local.west_tgw.id
# }

# resource "aws_route" "west_peering_routes_public" {
#   provider               = aws.us_west_2
#   for_each               = { for k, v in local.west_public_rts : k => v }
#   route_table_id         = each.value.id
#   destination_cidr_block = "10.200.0.0/14"
#   transit_gateway_id     = local.west_tgw.id
# }

# locals {
#   east_hub_rules = {

#     from_west_to_east_hub = {
#       description              = "Allow all from West hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_hub_sgs.public.id
#     }

#     from_west_to_east_private = {
#       description              = "Allow all from West"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/14"]
#       source_security_group_id = null
#       security_group_id        = local.east_hub_sgs.private.id
#     }
#   }
# }

# resource "aws_security_group_rule" "east_hub_rules" {
#   provider                 = aws.us_east_1
#   for_each                 = local.east_hub_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }

# locals {
#   west_hub_rules = {

#     from_east_to_west_public = {
#       description              = "Allow all from East hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_hub_sgs.public.id
#     }

#     from_east_to_west_private = {
#       description              = "Allow all from West"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/14"]
#       source_security_group_id = null
#       security_group_id        = local.west_hub_sgs.private.id
#     }
#   }
# }

# resource "aws_security_group_rule" "west_hub_rules" {
#   provider                 = aws.us_west_2
#   for_each                 = local.west_hub_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }

# locals {
#   east_spoke_rules = {

#     from_west_to_east_1 = {
#       description              = "Allow all from West hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[0].id
#     }

#     from_west_to_east_2 = {
#       description              = "Allow all from West spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.221.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[0].id
#     }

#     from_west_to_east_3 = {
#       description              = "Allow all from West spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.222.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[0].id
#     }

#     from_west_to_east_4 = {
#       description              = "Allow all from West hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[1].id
#     }

#     from_west_to_east_5 = {
#       description              = "Allow all from West spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.221.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[1].id
#     }

#     from_west_to_east_6 = {
#       description              = "Allow all from West spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.222.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[1].id
#     }

#     from_west_to_east_7 = {
#       description              = "Allow all from West hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[2].id
#     }

#     from_west_to_east_8 = {
#       description              = "Allow all from West spoke 3"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.223.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[2].id
#     }
#   }
# }

# resource "aws_security_group_rule" "east_spoke_rules" {
#   provider                 = aws.us_east_1
#   for_each                 = local.east_spoke_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }

# locals {
#   west_spoke_rules = {

#     from_east_to_west_1 = {
#       description              = "Allow all from East hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[0].id
#     }

#     from_east_to_west_2 = {
#       description              = "Allow all from East spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.201.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[0].id
#     }

#     from_east_to_west_3 = {
#       description              = "Allow all from East spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.202.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[0].id
#     }

#     from_east_to_west_4 = {
#       description              = "Allow all from East hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[1].id
#     }

#     from_east_to_west_5 = {
#       description              = "Allow all from East spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.201.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[1].id
#     }

#     from_east_to_west_6 = {
#       description              = "Allow all from East spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.202.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[1].id
#     }

#     from_east_to_west_7 = {
#       description              = "Allow all from East hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[2].id
#     }

#     from_east_to_west_8 = {
#       description              = "Allow all from East spoke 3"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.203.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[2].id
#     }
#   }
# }

# resource "aws_security_group_rule" "west_spoke_rules" {
#   provider                 = aws.us_west_2
#   for_each                 = local.west_spoke_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }
