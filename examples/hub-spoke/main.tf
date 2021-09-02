module "ssh_key" {
  source        = "../../modules/ssh-key"
  key_name      = "aws-test-key"
  priv_key_path = var.priv_key_path
}

module "east_hub_vpc" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  for_each  = var.east_hub_vpc_cidrs
  vpc_cidr  = each.value
  name      = var.east_hub_names[each.key]
  azs       = ["us-east-1a", "us-east-1b", "us-east-1d", "us-east-1e"]

  public_subnets = [
    cidrsubnet(var.east_hub_vpc_cidrs[each.key], 8, 0)
  ]
  private_subnets = [
    cidrsubnet(var.east_hub_vpc_cidrs[each.key], 8, 128),
    cidrsubnet(var.east_hub_vpc_cidrs[each.key], 8, 129)
  ]
}

module "east_spoke_vpc" {
  source     = "../../modules/vpc"
  providers  = { aws = aws.us_east_1 }
  for_each   = var.east_spke_vpc_cidrs
  vpc_cidr   = each.value
  name       = var.east_spoke_names[each.key]
  create_igw = false
  azs        = ["us-east-1a", "us-east-1b", "us-east-1d", "us-east-1e"]

  intra_subnets = [
    cidrsubnet(var.east_spke_vpc_cidrs[each.key], 8, 128),
    cidrsubnet(var.east_spke_vpc_cidrs[each.key], 8, 129)
  ]
}

locals {
  vpcs = {
    east = {
      hubs   = { for k, v in module.east_hub_vpc : k => v.vpc }
      spokes = { for k, v in module.east_spoke_vpc : k => v.vpc }
    }
  }
  private_subnets = {
    east = {
      hubs = { for k, v in module.east_hub_vpc : k => v.private_subnets }
    }
  }
  public_subnets = {
    east = {
      hubs = { for k, v in module.east_hub_vpc : k => v.public_subnets }
    }
  }
  intra_subnets = {
    east = {
      spokes = { for k, v in module.east_spoke_vpc : k => v.intra_subnets }
    }
  }
}

module "east_tgw" {
  source     = "../../modules/transit-gateway"
  providers  = { aws = aws.us_east_1 }
  create_tgw = true
  name       = "east-tgw"

  vpc_attachments = {
    hub1 = {
      vpc_id               = local.vpcs.east.hubs["hub1"].id
      subnet_ids           = local.private_subnets.east.hubs["hub1"][*].id
      default_asssociation = false
      default_propagation  = false
      tags = {
        Purpose = "Attachment to hub VPC"
      }
    },
    spoke1 = {
      vpc_id               = local.vpcs.east.spokes["spoke1"].id
      subnet_ids           = local.intra_subnets.east.spokes["spoke1"][*].id
      default_asssociation = false
      default_propagation  = false
    },
    spoke2 = {
      vpc_id               = local.vpcs.east.spokes["spoke2"].id
      subnet_ids           = local.intra_subnets.east.spokes["spoke2"][*].id
      default_asssociation = false
      default_propagation  = false
    },
    spoke3 = {
      vpc_id               = local.vpcs.east.spokes["spoke3"].id
      subnet_ids           = local.intra_subnets.east.spokes["spoke3"][*].id
      default_asssociation = false
      default_propagation  = false
    },
  }

  route_tables = {
    hubs = {
      tags = { Purpose = "RT attached to hub1 VPC" }
    }
    spokes = {
      tags = { Purpose = "RT attached to spoke VPC" }
    }
  }

  route_table_associations = {
    hub1   = { route_table_name = "hubs" }
    spoke1 = { route_table_name = "spokes" }
    spoke2 = { route_table_name = "spokes" }
    spoke3 = { route_table_name = "spokes" }
  }

  route_table_propagations = {
    hub_to_spokes = {
      attach_name      = "hub1"
      route_table_name = "spokes"
    }
    spoke_1_to_hub = {
      attach_name      = "spoke1"
      route_table_name = "hubs"
    }
    spoke_2_to_hub = {
      attach_name      = "spoke2"
      route_table_name = "hubs"
    }
    spoke_3_to_hub = {
      attach_name      = "spoke3"
      route_table_name = "hubs"
    }
    spoke_1_to_2 = {
      attach_name      = "spoke1"
      route_table_name = "spokes"
    }
    spoke_2_to_1 = {
      attach_name      = "spoke2"
      route_table_name = "spokes"
    }
  }

  tgw_routes = {
    spoke_default = {
      destination      = "0.0.0.0/0"
      attach_id        = "hub1"
      route_table_name = "spokes"
    }
    blackhole_1 = {
      destination      = "10.0.0.0/8"
      blackhole        = true
      route_table_name = "hubs"
    }
    blackhole_2 = {
      destination      = "10.0.0.0/8"
      blackhole        = true
      route_table_name = "spokes"
    }
    blackhole_3 = {
      destination      = "172.16.0.0/12"
      blackhole        = true
      route_table_name = "hubs"
    }
    blackhole_4 = {
      destination      = "172.16.0.0/12"
      blackhole        = true
      route_table_name = "spokes"
    }
    blackhole_5 = {
      destination      = "192.168.0.0/16"
      blackhole        = true
      route_table_name = "hubs"
    }
    blackhole_6 = {
      destination      = "192.168.0.0/16"
      blackhole        = true
      route_table_name = "spokes"
    }
  }
}

module "east_ec2" {
  source        = "../../modules/ec2"
  providers     = { aws = aws.us_east_1 }
  name          = "east-ec2"
  key_name      = "aws-test-key"
  priv_key      = module.ssh_key.priv_key
  priv_key_path = var.priv_key_path

  craate_custom_eni = true
  custom_eni_props = {
    hub1_public1 = {
      subnet_id       = local.public_subnets.east.hubs["hub1"][0].id
      security_groups = null
      private_ips     = [cidrhost(local.public_subnets.east.hubs["hub1"][0].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
    spoke1_intra1 = {
      subnet_id       = local.intra_subnets.east.spokes["spoke1"][0].id
      security_groups = null
      private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke1"][0].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
    spoke1_intra2 = {
      subnet_id       = local.intra_subnets.east.spokes["spoke1"][1].id
      security_groups = null
      private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke1"][1].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
    spoke2_intra1 = {
      subnet_id       = local.intra_subnets.east.spokes["spoke2"][0].id
      security_groups = null
      private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke2"][0].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
    spoke2_intra2 = {
      subnet_id       = local.intra_subnets.east.spokes["spoke2"][1].id
      security_groups = null
      private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke2"][1].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
    spoke3_intra1 = {
      subnet_id       = local.intra_subnets.east.spokes["spoke3"][0].id
      security_groups = null
      private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke3"][0].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
    spoke3_intra2 = {
      subnet_id       = local.intra_subnets.east.spokes["spoke3"][1].id
      security_groups = null
      private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke3"][1].cidr_block, 10)]
      tags = {
        Attach = "For HUB1 Public ENI"
      }
    }
  }
}

# resource "aws_ec2_transit_gateway_peering_attachment" "east_west" {
#   provider                = aws.us_east_1
#   peer_region             = local.west_region
#   transit_gateway_id      = local.east_tgw.id
#   peer_transit_gateway_id = local.west_tgw.id

#   tags = {
#     Name = "EAST->WEST"
#   }
# }

# resource "aws_ec2_transit_gateway_peering_attachment_accepter" "east_west" {
#   provider                      = aws.us_west_2
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.east_west.id

#   tags = {
#     Name = "WEST->EAST"
#   }
# }

# resource "aws_ec2_transit_gateway_route_table" "east_to_west" {
#   provider           = aws.us_east_1
#   transit_gateway_id = local.east_tgw.id

#   tags = {
#     Name = "EAST->WEST"
#   }
# }

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
