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

  vpc_endpoint_route_table_association = {
    public = {
      route_table_id  = module.east_hub.public_route_table_id
      vpc_endpoint_id = module.east_hub.vpc_endpoint_ids[0]
    },
    private = {
      route_table_id  = module.east_hub.private_route_table_id
      vpc_endpoint_id = module.east_hub.vpc_endpoint_ids[0]
    },
    intra = {
      route_table_id  = module.east_hub.intra_route_table_id
      vpc_endpoint_id = module.east_hub.vpc_endpoint_ids[0]
    },
  }

  flow_logs_role        = { east_hub1 = {} }
  flow_logs_role_policy = { east_hub1 = {} }
  cloudwatch_log_groups = { east_hub1 = {} }
  flow_logs             = { east_hub1 = {} }

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
      cidr_blocks       = ["${var.lab_public_ip}/32"]
      security_group_id = module.east_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow SSH from home"
      type              = "ingress"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = ["${var.lab_public_ip}/32"]
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
      description = "Allow all sourced from west hub to east hub"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_hub.cidr_block,
      ]
      security_group_id = module.east_hub.security_group_ids["public1"]
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
        module.west_hub.cidr_block,
        module.west_spoke1.cidr_block,
        module.west_spoke2.cidr_block,
        module.west_spoke3.cidr_block,
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
        module.west_hub.cidr_block,
        module.west_spoke1.cidr_block,
        module.west_spoke2.cidr_block,
        module.west_spoke3.cidr_block,
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

  vpc_endpoints = [{
    endpoint_type   = "Gateway"
    service_type    = "s3"
    policy          = local.east_data.s3_endpoint_policy
    route_table_ids = module.east_spoke1.route_table_ids
    tags = {
      Name = "east-spoke1-s3-endpoint"
    }
  }]

  vpc_endpoint_route_table_association = {
    intra = {
      route_table_id  = module.east_spoke1.intra_route_table_id
      vpc_endpoint_id = module.east_spoke1.vpc_endpoint_ids[0]
    },
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
      description = "Allow all sourced from hub and spoke2 east spoke 1-2 west to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
        module.east_spoke2.cidr_block,
        module.west_hub.cidr_block,
        module.west_spoke1.cidr_block,
        module.west_spoke2.cidr_block,
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

  vpc_endpoints = [{
    endpoint_type   = "Gateway"
    service_type    = "s3"
    policy          = local.east_data.s3_endpoint_policy
    route_table_ids = module.east_spoke2.route_table_ids
    tags = {
      Name = "east-spoke2-s3-endpoint"
    }
  }]

  vpc_endpoint_route_table_association = {
    intra = {
      route_table_id  = module.east_spoke2.intra_route_table_id
      vpc_endpoint_id = module.east_spoke2.vpc_endpoint_ids[0]
    },
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
      description = "Allow all sourced from hub and spoke2 east spoke 1-2 west to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
        module.east_spoke1.cidr_block,
        module.west_hub.cidr_block,
        module.west_spoke1.cidr_block,
        module.west_spoke2.cidr_block,
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

  vpc_endpoints = [{
    endpoint_type   = "Gateway"
    service_type    = "s3"
    policy          = local.east_data.s3_endpoint_policy
    route_table_ids = module.east_spoke3.route_table_ids
    tags = {
      Name = "east-spoke3-s3-endpoint"
    }
  }]

  vpc_endpoint_route_table_association = {
    intra = {
      route_table_id  = module.east_spoke3.intra_route_table_id
      vpc_endpoint_id = module.east_spoke3.vpc_endpoint_ids[0]
    },
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
      description = "Allow all sourced from hub, hub and spoke3 west to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
        module.west_hub.cidr_block,
        module.west_spoke3.cidr_block,
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
  name      = "east"

  transit_gateway = [{
    dns_support                     = "enable"
    description                     = "US East Transit Gateway"
    amazon_side_asn                 = var.amzn_side_asn
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

  transit_gateway_peering_attachment = {
    east_to_west = {
      peer_region             = "us-west-2"
      transit_gateway_id      = module.east_transit_gateway.transit_gateway_id
      peer_transit_gateway_id = module.west_transit_gateway.transit_gateway_id
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
    east_to_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
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
    hub_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke1_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke2_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke3_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
  }

  transit_gateway_routes = [
    {
      destination                   = "0.0.0.0/0"
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination                   = var.cidr_blocks.west["supernet"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
      transit_gateway_attachment_id = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
    },
    {
      destination                   = var.cidr_blocks.west["supernet"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
      transit_gateway_attachment_id = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
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
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke1.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke2.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke3.intra_route_table_id
    },
  ]
}

module "east_vpn" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east_vpn"

  customer_gateway = {
    east_vpn = {
      bgp_asn     = var.customer_side_asn
      device_name = "east_vpn"
      ip_address  = var.lab_public_ip
      type        = "ipsec.1"
    }
  }

  vpn_connection = {
    east_vpn = {
      transit_gateway_id                   = module.east_transit_gateway.transit_gateway_id
      static_routes_only                   = false
      tunnel1_preshared_key                = var.tunnel1_preshared_key
      tunnel2_preshared_key                = var.tunnel2_preshared_key
      tunnel1_inside_cidr                  = "169.254.200.0/30"
      tunnel2_inside_cidr                  = "169.254.200.4/30"
      tunnel1_ike_versions                 = ["ikev2"]
      tunnel2_ike_versions                 = ["ikev2"]
      tunnel1_phase1_dh_group_numbers      = ["14"]
      tunnel2_phase1_dh_group_numbers      = ["14"]
      tunnel1_phase1_integrity_algorithms  = ["SHA1"]
      tunnel2_phase1_integrity_algorithms  = ["SHA1"]
      tunnel1_phase1_encryption_algorithms = ["AES128"]
      tunnel2_phase1_encryption_algorithms = ["AES128"]
      tunnel1_phase2_dh_group_numbers      = ["14"]
      tunnel2_phase2_dh_group_numbers      = ["14"]
      tunnel1_phase2_integrity_algorithms  = ["SHA1"]
      tunnel2_phase2_integrity_algorithms  = ["SHA1"]
      tunnel1_phase2_encryption_algorithms = ["AES128"]
      tunnel2_phase2_encryption_algorithms = ["AES128"]
    }
  }

  transit_gateway_route_tables = {
    east_vpn = {
      transit_gateway_id = module.east_transit_gateway.transit_gateway_id
    }
  }
  transit_gateway_route_table_associations = {
    east_vpn = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
  }
  transit_gateway_route_table_propagations = {
    vpn_to_hubs = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    }
    vpn_to_spokes = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    }
    vpn_to_east_west = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    hub_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
    spoke1_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
    spoke2_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
    spoke3_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
  }

  vpc_routes = [
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.east_hub.public_route_table_id
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.east_hub.private_route_table_id
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.east_hub.intra_route_table_id
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
    }
  ]

  security_group_rules = [
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_hub.security_group_ids["private1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_hub.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_spoke1.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_spoke2.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_spoke3.security_group_ids["intra1"]
    },
  ]
}

### -------------------------------------------------------------------------------------------- ###
### WEST DATA
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

  vpc_endpoint_route_table_association = {
    public = {
      route_table_id  = module.west_hub.public_route_table_id
      vpc_endpoint_id = module.west_hub.vpc_endpoint_ids[0]
    },
    private = {
      route_table_id  = module.west_hub.private_route_table_id
      vpc_endpoint_id = module.west_hub.vpc_endpoint_ids[0]
    },
    intra = {
      route_table_id  = module.west_hub.intra_route_table_id
      vpc_endpoint_id = module.west_hub.vpc_endpoint_ids[0]
    },
  }

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
      cidr_blocks       = ["${var.lab_public_ip}/32"]
      security_group_id = module.west_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow SSH from home"
      type              = "ingress"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = ["${var.lab_public_ip}/32"]
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
      description = "Allow all sourced from east hub to west hub"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.east_hub.cidr_block,
      ]
      security_group_id = module.west_hub.security_group_ids["public1"]
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
        module.east_hub.cidr_block,
        module.east_spoke1.cidr_block,
        module.east_spoke2.cidr_block,
        module.east_spoke3.cidr_block,
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
        module.east_hub.cidr_block,
        module.east_spoke1.cidr_block,
        module.east_spoke2.cidr_block,
        module.east_spoke3.cidr_block,
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

  vpc_endpoints = [{
    endpoint_type   = "Gateway"
    service_type    = "s3"
    policy          = local.west_data.s3_endpoint_policy
    route_table_ids = module.west_spoke1.route_table_ids
    tags = {
      Name = "west-spoke1-s3-endpoint"
    }
  }]

  vpc_endpoint_route_table_association = {
    intra = {
      vpc_endpoint_id = module.west_spoke1.vpc_endpoint_ids[0]
      route_table_id  = module.west_spoke1.intra_route_table_id
    },
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
      description = "Allow all sourced from hub and spoke2 and east to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_hub.cidr_block,
        module.west_spoke2.cidr_block,
        module.east_hub.cidr_block,
        module.east_spoke1.cidr_block,
        module.east_spoke2.cidr_block,
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

  vpc_endpoints = [{
    endpoint_type   = "Gateway"
    service_type    = "s3"
    policy          = local.west_data.s3_endpoint_policy
    route_table_ids = module.west_spoke2.route_table_ids
    tags = {
      Name = "west-spoke2-s3-endpoint"
    }
  }]

  vpc_endpoint_route_table_association = {
    intra = {
      route_table_id  = module.west_spoke2.intra_route_table_id
      vpc_endpoint_id = module.west_spoke2.vpc_endpoint_ids[0]
    },
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
      description = "Allow all sourced from hub and spoke1 and east to intra"
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
        module.west_hub.cidr_block,
        module.west_spoke1.cidr_block,
        module.east_hub.cidr_block,
        module.east_spoke1.cidr_block,
        module.east_spoke2.cidr_block,
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

  vpc_endpoints = [{
    endpoint_type   = "Gateway"
    service_type    = "s3"
    policy          = local.west_data.s3_endpoint_policy
    route_table_ids = module.west_spoke3.route_table_ids
    tags = {
      Name = "west-spoke3-s3-endpoint"
    }
  }]

  vpc_endpoint_route_table_association = {
    intra = {
      route_table_id  = module.west_spoke3.intra_route_table_id
      vpc_endpoint_id = module.west_spoke3.vpc_endpoint_ids[0]
    },
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
        module.east_hub.cidr_block,
        module.east_spoke3.cidr_block,
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
  name      = "west"

  transit_gateway = [{
    dns_support                     = "enable"
    description                     = "US East Transit Gateway"
    amazon_side_asn                 = var.amzn_side_asn
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

  transit_gateway_peering_attachment_accepter = {
    east_to_west = {
      transit_gateway_peering_attachment = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
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
    east_to_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.transit_gateway_peering_attachment_accepter_ids["east_to_west"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
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
    hub_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke1_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke2_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke3_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
  }

  transit_gateway_routes = [
    {
      destination                   = "0.0.0.0/0"
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
    },
    {
      destination                   = var.cidr_blocks.east["supernet"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
      transit_gateway_attachment_id = module.west_transit_gateway.transit_gateway_peering_attachment_accepter_ids["east_to_west"]
    },
    {
      destination                   = var.cidr_blocks.east["supernet"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
      transit_gateway_attachment_id = module.west_transit_gateway.transit_gateway_peering_attachment_accepter_ids["east_to_west"]
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
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke1.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke2.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke3.intra_route_table_id
    },
  ]
}

module "west_vpn" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_west_2 }
  name      = "west_vpn"

  customer_gateway = {
    west_vpn = {
      bgp_asn     = var.customer_side_asn
      device_name = "west_vpn"
      ip_address  = var.lab_public_ip
      type        = "ipsec.1"
    }
  }

  vpn_connection = {
    west_vpn = {
      transit_gateway_id                   = module.west_transit_gateway.transit_gateway_id
      static_routes_only                   = false
      tunnel1_preshared_key                = var.tunnel1_preshared_key
      tunnel2_preshared_key                = var.tunnel2_preshared_key
      tunnel1_inside_cidr                  = "169.254.220.0/30"
      tunnel2_inside_cidr                  = "169.254.220.4/30"
      tunnel1_ike_versions                 = ["ikev2"]
      tunnel2_ike_versions                 = ["ikev2"]
      tunnel1_phase1_dh_group_numbers      = ["14"]
      tunnel2_phase1_dh_group_numbers      = ["14"]
      tunnel1_phase1_integrity_algorithms  = ["SHA1"]
      tunnel2_phase1_integrity_algorithms  = ["SHA1"]
      tunnel1_phase1_encryption_algorithms = ["AES128"]
      tunnel2_phase1_encryption_algorithms = ["AES128"]
      tunnel1_phase2_dh_group_numbers      = ["14"]
      tunnel2_phase2_dh_group_numbers      = ["14"]
      tunnel1_phase2_integrity_algorithms  = ["SHA1"]
      tunnel2_phase2_integrity_algorithms  = ["SHA1"]
      tunnel1_phase2_encryption_algorithms = ["AES128"]
      tunnel2_phase2_encryption_algorithms = ["AES128"]
    }
  }

  transit_gateway_route_tables = {
    west_vpn = {
      transit_gateway_id = module.west_transit_gateway.transit_gateway_id
    }
  }
  transit_gateway_route_table_associations = {
    west_vpn = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
  }
  transit_gateway_route_table_propagations = {
    vpn_to_hubs = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    }
    vpn_to_spokes = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    }
    vpn_to_east_west = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    hub_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
    spoke1_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
    spoke2_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
    spoke3_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
  }

  vpc_routes = [
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.west_hub.public_route_table_id
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.west_hub.private_route_table_id
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.west_hub.intra_route_table_id
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
    }
  ]

  security_group_rules = [
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_hub.security_group_ids["private1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_hub.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_spoke1.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_spoke2.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_spoke3.security_group_ids["intra1"]
    },
  ]
}
