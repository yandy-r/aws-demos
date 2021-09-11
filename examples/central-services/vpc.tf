### -------------------------------------------------------------------------------------------- ###
### US-EAST-1 INFRASTRUCTURE
### -------------------------------------------------------------------------------------------- ###

module "east_hub" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east-hub"

  vpc_dhcp_optons = [
    { domain_name = var.zone_names["east"] },
  ]
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
      map_public_ip_on_launch = false
    },
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 65)
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = false
    }
  ]

  intra_subnets = [
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 128)
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
    },
    {
      cidr_block              = cidrsubnet(module.east_hub.cidr_block, 8, 129)
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = false
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
      map_public_ip_on_launch = false
    },
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 65)
      availability_zone       = "us-west-2b"
      map_public_ip_on_launch = false
    }
  ]

  intra_subnets = [
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 128)
      availability_zone       = "us-west-2a"
      map_public_ip_on_launch = false
    },
    {
      cidr_block              = cidrsubnet(module.west_hub.cidr_block, 8, 129)
      availability_zone       = "us-west-2b"
      map_public_ip_on_launch = false
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
