module "tgw_east" {
  source                = "./transit-gw"
  providers             = { aws = aws.us_east_1 }
  self_public_ip        = var.self_public_ip
  priv_ssh_key_path     = var.priv_ssh_key_path
  domain_name           = var.domain_name_east
  create_flow_logs      = var.create_flow_logs
  create_vpc_endpoint   = var.create_vpc_endpoint
  bucket_name           = "east-3-${var.bucket_name}"
  region                = "us-east-1"
  create_peering_routes = true

  vpc_cidr_blocks = [
    "10.200.0.0/16",
    "10.201.0.0/16",
    "10.202.0.0/16",
    "10.203.0.0/16"
  ]

  hostnames = [
    "hub-e-bastion",
    "hub-e-private",
    "spoke-e-1",
    "spoke-e-2",
    "spoke-e-3"
  ]
}

module "tgw_west" {
  source                = "./transit-gw"
  providers             = { aws = aws.us_west_2 }
  self_public_ip        = var.self_public_ip
  priv_ssh_key_path     = var.priv_ssh_key_path
  domain_name           = var.domain_name_east
  create_flow_logs      = var.create_flow_logs
  create_vpc_endpoint   = var.create_vpc_endpoint
  bucket_name           = "west2-3-${var.bucket_name}"
  region                = "us-west-2"
  create_peering_routes = true

  vpc_cidr_blocks = [
    "10.220.0.0/16",
    "10.221.0.0/16",
    "10.222.0.0/16",
    "10.223.0.0/16"
  ]

  hostnames = [
    "hub-w-bastion",
    "hub-w-private",
    "spoke-w-1",
    "spoke-w-2",
    "spoke-w-3"
  ]
}

locals {
  east_subnets         = module.tgw_east.subnets
  private_east_subnets = module.tgw_east.subnets.private
  public_east_subnets  = module.tgw_east.subnets.public
  east_private_rts     = module.tgw_east.route_tables.private
  east_public_rts      = module.tgw_east.route_tables.public
  east_tgw             = module.tgw_east.tgw
  east_tgw_rts         = module.tgw_east.tgw_rts
  east_tgw_attach_id   = module.tgw_east.tgw_attach_id
  east_region          = module.tgw_east.aws_region
  east_hub_sgs         = module.tgw_east.hub_sgs
  east_spoke_sgs       = module.tgw_east.spoke_sgs

  all_east_tgw_rts = [
    aws_ec2_transit_gateway_route_table.east_to_west,
    module.tgw_east.tgw_rts[0],
    module.tgw_east.tgw_rts[1]
  ]

  west_subnets         = module.tgw_west.subnets
  private_west_subnets = module.tgw_west.subnets.private
  public_west_subnets  = module.tgw_west.subnets.public
  west_private_rts     = module.tgw_west.route_tables.private
  west_public_rts      = module.tgw_west.route_tables.public
  west_tgw             = module.tgw_west.tgw
  west_tgw_rts         = module.tgw_west.tgw_rts
  west_tgw_attach_id   = module.tgw_west.tgw_attach_id
  west_region          = module.tgw_west.aws_region
  west_hub_sgs         = module.tgw_west.hub_sgs
  west_spoke_sgs       = module.tgw_west.spoke_sgs

  all_west_tgw_rts = [
    aws_ec2_transit_gateway_route_table.west_to_east,
    module.tgw_west.tgw_rts[0],
    module.tgw_west.tgw_rts[1]
  ]
}

resource "aws_ec2_transit_gateway_peering_attachment" "east_west" {
  provider                = aws.us_east_1
  peer_region             = local.west_region
  transit_gateway_id      = local.east_tgw.id
  peer_transit_gateway_id = local.west_tgw.id

  tags = {
    Name = "EAST->WEST"
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "east_west" {
  provider                      = aws.us_west_2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.east_west.id

  tags = {
    Name = "WEST->EAST"
  }
}

resource "aws_ec2_transit_gateway_route_table" "east_to_west" {
  provider           = aws.us_east_1
  transit_gateway_id = local.east_tgw.id

  tags = {
    Name = "EAST->WEST"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "east_to_west" {
  provider                       = aws.us_east_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.east_west.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
}

resource "aws_ec2_transit_gateway_route" "east_to_west" {
  provider                       = aws.us_east_1
  for_each                       = { for k, v in local.all_east_tgw_rts : k => v }
  destination_cidr_block         = "10.220.0.0/14"
  transit_gateway_route_table_id = each.value.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.east_west.id
}

resource "aws_ec2_transit_gateway_route" "east_peering_to_hub_vpc" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "10.200.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
  transit_gateway_attachment_id  = local.east_tgw_attach_id[0]
}

resource "aws_ec2_transit_gateway_route" "east_peering_to_spoke_1_vpc" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "10.201.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
  transit_gateway_attachment_id  = local.east_tgw_attach_id[1]
}

resource "aws_ec2_transit_gateway_route" "east_peering_to_spoke_2_vpc" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "10.202.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
  transit_gateway_attachment_id  = local.east_tgw_attach_id[2]
}

resource "aws_ec2_transit_gateway_route" "east_peering_to_spoke_3_vpc" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "10.203.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east_to_west.id
  transit_gateway_attachment_id  = local.east_tgw_attach_id[3]
}

resource "aws_route" "east_peering_routes_private" {
  provider               = aws.us_east_1
  for_each               = { for k, v in local.east_private_rts : k => v }
  route_table_id         = each.value.id
  destination_cidr_block = "10.220.0.0/14"
  transit_gateway_id     = local.east_tgw.id
}

resource "aws_route" "east_peering_routes_public" {
  provider               = aws.us_east_1
  for_each               = { for k, v in local.east_public_rts : k => v }
  route_table_id         = each.value.id
  destination_cidr_block = "10.220.0.0/14"
  transit_gateway_id     = local.east_tgw.id
}

resource "aws_ec2_transit_gateway_route_table" "west_to_east" {
  provider           = aws.us_west_2
  transit_gateway_id = local.west_tgw.id

  tags = {
    Name = "WEST->EAST"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "west_to_east" {
  provider                       = aws.us_west_2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.east_west.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
}

resource "aws_ec2_transit_gateway_route" "west_to_east" {
  provider                       = aws.us_west_2
  for_each                       = { for k, v in local.all_west_tgw_rts : k => v }
  destination_cidr_block         = "10.200.0.0/14"
  transit_gateway_route_table_id = each.value.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.east_west.id
}

resource "aws_ec2_transit_gateway_route" "west_peering_to_hub_vpc" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "10.220.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
  transit_gateway_attachment_id  = local.west_tgw_attach_id[0]
}

resource "aws_ec2_transit_gateway_route" "west_peering_to_spoke_1_vpc" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "10.221.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
  transit_gateway_attachment_id  = local.west_tgw_attach_id[1]
}

resource "aws_ec2_transit_gateway_route" "west_peering_to_spoke_2_vpc" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "10.222.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
  transit_gateway_attachment_id  = local.west_tgw_attach_id[2]
}

resource "aws_ec2_transit_gateway_route" "west_peering_to_spoke_3_vpc" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "10.223.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west_to_east.id
  transit_gateway_attachment_id  = local.west_tgw_attach_id[3]
}

resource "aws_route" "west_peering_routes_private" {
  provider               = aws.us_west_2
  for_each               = { for k, v in local.west_private_rts : k => v }
  route_table_id         = each.value.id
  destination_cidr_block = "10.200.0.0/14"
  transit_gateway_id     = local.west_tgw.id
}

resource "aws_route" "west_peering_routes_public" {
  provider               = aws.us_west_2
  for_each               = { for k, v in local.west_public_rts : k => v }
  route_table_id         = each.value.id
  destination_cidr_block = "10.200.0.0/14"
  transit_gateway_id     = local.west_tgw.id
}

locals {
  east_hub_rules = {

    from_west_to_east_hub = {
      description              = "Allow all from West Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.220.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_hub_sgs.public.id
    }

    from_west_to_east_private = {
      description              = "Allow all from West"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.220.0.0/14"]
      source_security_group_id = null
      security_group_id        = local.east_hub_sgs.private.id
    }
  }
}

resource "aws_security_group_rule" "east_hub_rules" {
  provider                 = aws.us_east_1
  for_each                 = local.east_hub_rules
  description              = each.value.description
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = each.value.security_group_id
}

locals {
  west_hub_rules = {

    from_east_to_west_public = {
      description              = "Allow all from East Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.200.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_hub_sgs.public.id
    }

    from_east_to_west_private = {
      description              = "Allow all from West"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.200.0.0/14"]
      source_security_group_id = null
      security_group_id        = local.west_hub_sgs.private.id
    }
  }
}

resource "aws_security_group_rule" "west_hub_rules" {
  provider                 = aws.us_west_2
  for_each                 = local.west_hub_rules
  description              = each.value.description
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = each.value.security_group_id
}

locals {
  east_spoke_rules = {

    from_west_to_east_1 = {
      description              = "Allow all from West Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.220.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[0].id
    }

    from_west_to_east_2 = {
      description              = "Allow all from West Spoke 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.221.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[0].id
    }

    from_west_to_east_3 = {
      description              = "Allow all from West Spoke 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.222.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[0].id
    }

    from_west_to_east_4 = {
      description              = "Allow all from West Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.220.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[1].id
    }

    from_west_to_east_5 = {
      description              = "Allow all from West Spoke 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.221.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[1].id
    }

    from_west_to_east_6 = {
      description              = "Allow all from West Spoke 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.222.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[1].id
    }

    from_west_to_east_7 = {
      description              = "Allow all from West Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.220.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[2].id
    }

    from_west_to_east_8 = {
      description              = "Allow all from West Spoke 3"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.223.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.east_spoke_sgs[2].id
    }
  }
}

resource "aws_security_group_rule" "east_spoke_rules" {
  provider                 = aws.us_east_1
  for_each                 = local.east_spoke_rules
  description              = each.value.description
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = each.value.security_group_id
}

locals {
  west_spoke_rules = {

    from_east_to_west_1 = {
      description              = "Allow all from East Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.200.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[0].id
    }

    from_east_to_west_2 = {
      description              = "Allow all from East Spoke 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.201.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[0].id
    }

    from_east_to_west_3 = {
      description              = "Allow all from East Spoke 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.202.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[0].id
    }

    from_east_to_west_4 = {
      description              = "Allow all from East Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.200.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[1].id
    }

    from_east_to_west_5 = {
      description              = "Allow all from East Spoke 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.201.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[1].id
    }

    from_east_to_west_6 = {
      description              = "Allow all from East Spoke 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.202.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[1].id
    }

    from_east_to_west_7 = {
      description              = "Allow all from East Hub"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.200.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[2].id
    }

    from_east_to_west_8 = {
      description              = "Allow all from East Spoke 3"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.203.0.0/16"]
      source_security_group_id = null
      security_group_id        = local.west_spoke_sgs[2].id
    }
  }
}

resource "aws_security_group_rule" "west_spoke_rules" {
  provider                 = aws.us_west_2
  for_each                 = local.west_spoke_rules
  description              = each.value.description
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = each.value.security_group_id
}

# output "public_east_ec2" {
#   value = [for v in module.tgw_east.public_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     public_ip  = v.public_ip
#     } if v.public_ip != ""
#   ]
# }

# output "private_east_ec2" {
#   value = [for v in module.tgw_east.private_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     }
#   ]
# }

# output "public_west_ec2" {
#   value = [for v in module.tgw_west.public_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     public_ip  = v.public_ip
#     } if v.public_ip != ""
#   ]
# }

# output "private_west_ec2" {
#   value = [for v in module.tgw_west.private_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     }
#   ]
# }

# output "vpc_east_info" {
#   value = [
#     for v in module.tgw_east.vpcs : {
#       name       = v.tags_all.Name
#       id         = v.id,
#       cidr_block = v.cidr_block
#     }
#   ]
# }




# FOR LATER

# output "east_subnets" {
#   value = {
#     for k, v in module.tgw_east.subnets : k => [
#       for i in v : {
#         name              = i.tags_all.Name
#         id                = i.id
#         vpc_id            = i.vpc_id
#         cidr_block        = i.cidr_block
#         availability_zone = i.availability_zone
#       }
#     ]
#   }
# }

# output "private_east_subnets" {
#   value = [
#     for v in local.private_subnets : {
#       name              = v.tags_all.Name
#       id                = v.id
#       vpc_id            = v.vpc_id
#       cidr_block        = v.cidr_block
#       availability_zone = v.availability_zone
#     }
#   ]
# }

# output "public_east_subnets" {
#   value = [
#     for v in local.public_subnets : {
#       name              = v.tags_all.Name
#       id                = v.id
#       vpc_id            = v.vpc_id
#       cidr_block        = v.cidr_block
#       availability_zone = v.availability_zone
#     }
#   ]
# }
