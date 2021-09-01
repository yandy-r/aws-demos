### -------------------------------------------------------------------------------------------- ###
### PROVIDERS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.56"
    }
  }
}

locals {
  aws_profile = var.aws_profile.sandbox
}

provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = var.credentials_file
  profile                 = local.aws_profile

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
      Region      = "US-East-1"
    }
  }
}

provider "aws" {
  alias                   = "us_east_1"
  region                  = "us-east-1"
  shared_credentials_file = var.credentials_file
  profile                 = local.aws_profile

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
      Region      = "US-East-1"
    }
  }
}

provider "aws" {
  alias                   = "us_west_2"
  region                  = "us-west-2"
  shared_credentials_file = var.credentials_file
  profile                 = local.aws_profile

  default_tags {
    tags = {
      Terraform   = "True"
      Environemnt = "Test"
      Owner       = "Dev"
      Region      = "US-West-2"
    }
  }
}

### -------------------------------------------------------------------------------------------- ###
### MODULES
### -------------------------------------------------------------------------------------------- ###

module "ssh_key" {
  source        = "./ssh-key"
  key_name      = "aws-test-key"
  priv_key_path = var.priv_key_path
}

module "east_hub_vpc" {
  source    = "./vpc"
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
  source     = "./vpc"
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
  east_hub_vpc             = module.east_hub_vpc["Hub"].vpc_id
  east_spoke_vpc           = [for v in module.east_spoke_vpc : v.vpc_id]
  east_hub_private_subnets = module.east_hub_vpc["Hub"].private_subnets
  east_spoke_intra_subnets = [for v in module.east_spoke_vpc : v.intra_subnets]
  east_hub_cidr            = module.east_hub_vpc["Hub"].vpc_cidr
  east_spoke_cidr          = [for v in module.east_spoke_vpc : v.vpc_cidr]
}

module "east_tgw" {
  source     = "./transit-gateway"
  providers  = { aws = aws.us_east_1 }
  create_tgw = true
  name       = "EastTGW"

  vpc_attachments = {
    Hub = {
      vpc_id               = local.east_hub_vpc
      subnet_ids           = local.east_hub_private_subnets
      default_asssociation = false
      default_propagation  = false
      tags = {
        Purpose = "Attachment to Hub VPC"
      }
    },
    Spoke1 = {
      vpc_id               = local.east_spoke_vpc[0]
      subnet_ids           = local.east_spoke_intra_subnets[0]
      default_asssociation = false
      default_propagation  = false
    },
    Spoke2 = {
      vpc_id               = local.east_spoke_vpc[1]
      subnet_ids           = local.east_spoke_intra_subnets[1]
      default_asssociation = false
      default_propagation  = false
    },
    Spoke3 = {
      vpc_id               = local.east_spoke_vpc[2]
      subnet_ids           = local.east_spoke_intra_subnets[2]
      default_asssociation = false
      default_propagation  = false
    },
  }

  route_tables = {
    Hub = {
      tags = { Purpose = "RT attached to Hub VPC" }
    }
    Spokes = {
      tags = { Purpose = "RT attached to Spoke VPC" }
    }
  }

  route_table_associations = {
    Hub    = { route_table_name = "Hub" }
    Spoke1 = { route_table_name = "Spokes" }
    Spoke2 = { route_table_name = "Spokes" }
    Spoke3 = { route_table_name = "Spokes" }
  }

  route_table_propagations = {
    hub_to_spokes = {
      attach_name      = "Hub"
      route_table_name = "Spokes"
    }
    spoke_1_to_hub = {
      attach_name      = "Spoke1"
      route_table_name = "Hub"
    }
    spoke_2_to_hub = {
      attach_name      = "Spoke2"
      route_table_name = "Hub"
    }
    spoke_3_to_hub = {
      attach_name      = "Spoke3"
      route_table_name = "Hub"
    }
    spoke_1_to_2 = {
      attach_name      = "Spoke1"
      route_table_name = "Spokes"
    }
    spoke_2_to_1 = {
      attach_name      = "Spoke2"
      route_table_name = "Spokes"
    }
  }

  tgw_routes = {
    spoke_default = {
      destination      = "0.0.0.0/0"
      attach_id        = "Hub"
      route_table_name = "Spokes"
    }
    blackhole_1 = {
      destination      = "10.0.0.0/8"
      blackhole        = true
      route_table_name = "Hub"
    }
    blackhole_2 = {
      destination      = "10.0.0.0/8"
      blackhole        = true
      route_table_name = "Spokes"
    }
    blackhole_3 = {
      destination      = "172.16.0.0/12"
      blackhole        = true
      route_table_name = "Hub"
    }
    blackhole_4 = {
      destination      = "172.16.0.0/12"
      blackhole        = true
      route_table_name = "Spokes"
    }
    blackhole_5 = {
      destination      = "192.168.0.0/16"
      blackhole        = true
      route_table_name = "Hub"
    }
    blackhole_6 = {
      destination      = "192.168.0.0/16"
      blackhole        = true
      route_table_name = "Spokes"
    }
  }
}

# locals {
#   east_tgw_vpc_ids     = [for v in module.tgw_east.vpcs : v.id]
#   east_subnets         = module.tgw_east.subnets
#   private_east_subnets = module.tgw_east.subnets.private
#   public_east_subnets  = module.tgw_east.subnets.public
#   east_private_rts     = module.tgw_east.route_tables.private
#   east_public_rts      = module.tgw_east.route_tables.public
#   east_tgw             = module.tgw_east.tgw
#   east_tgw_rts         = module.tgw_east.tgw_rts
#   east_tgw_attach_id   = module.tgw_east.tgw_attach_id
#   east_region          = module.tgw_east.aws_region
#   east_hub_sgs         = module.tgw_east.hub_sgs
#   east_spoke_sgs       = module.tgw_east.spoke_sgs

#   all_east_tgw_rts = [
#     aws_ec2_transit_gateway_route_table.east_to_west,
#     module.tgw_east.tgw_rts[0],
#     module.tgw_east.tgw_rts[1]
#   ]

#   west_tgw_vpc_ids     = [for v in module.tgw_west.vpcs : v.id]
#   west_subnets         = module.tgw_west.subnets
#   private_west_subnets = module.tgw_west.subnets.private
#   public_west_subnets  = module.tgw_west.subnets.public
#   west_private_rts     = module.tgw_west.route_tables.private
#   west_public_rts      = module.tgw_west.route_tables.public
#   west_tgw             = module.tgw_west.tgw
#   west_tgw_rts         = module.tgw_west.tgw_rts
#   west_tgw_attach_id   = module.tgw_west.tgw_attach_id
#   west_region          = module.tgw_west.aws_region
#   west_hub_sgs         = module.tgw_west.hub_sgs
#   west_spoke_sgs       = module.tgw_west.spoke_sgs

#   all_west_tgw_rts = [
#     aws_ec2_transit_gateway_route_table.west_to_east,
#     module.tgw_west.tgw_rts[0],
#     module.tgw_west.tgw_rts[1]
#   ]
# }

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
#       description              = "Allow all from West Hub"
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
#       description              = "Allow all from East Hub"
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
#       description              = "Allow all from West Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[0].id
#     }

#     from_west_to_east_2 = {
#       description              = "Allow all from West Spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.221.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[0].id
#     }

#     from_west_to_east_3 = {
#       description              = "Allow all from West Spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.222.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[0].id
#     }

#     from_west_to_east_4 = {
#       description              = "Allow all from West Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[1].id
#     }

#     from_west_to_east_5 = {
#       description              = "Allow all from West Spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.221.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[1].id
#     }

#     from_west_to_east_6 = {
#       description              = "Allow all from West Spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.222.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[1].id
#     }

#     from_west_to_east_7 = {
#       description              = "Allow all from West Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.220.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.east_spoke_sgs[2].id
#     }

#     from_west_to_east_8 = {
#       description              = "Allow all from West Spoke 3"
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
#       description              = "Allow all from East Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[0].id
#     }

#     from_east_to_west_2 = {
#       description              = "Allow all from East Spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.201.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[0].id
#     }

#     from_east_to_west_3 = {
#       description              = "Allow all from East Spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.202.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[0].id
#     }

#     from_east_to_west_4 = {
#       description              = "Allow all from East Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[1].id
#     }

#     from_east_to_west_5 = {
#       description              = "Allow all from East Spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.201.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[1].id
#     }

#     from_east_to_west_6 = {
#       description              = "Allow all from East Spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.202.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[1].id
#     }

#     from_east_to_west_7 = {
#       description              = "Allow all from East Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["10.200.0.0/16"]
#       source_security_group_id = null
#       security_group_id        = local.west_spoke_sgs[2].id
#     }

#     from_east_to_west_8 = {
#       description              = "Allow all from East Spoke 3"
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
