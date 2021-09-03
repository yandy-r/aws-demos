module "ssh_key" {
  source        = "../../modules/ssh-key"
  key_name      = "aws-test-key"
  priv_key_path = var.priv_key_path
}

# data "aws_region" "current" {}
# data "template_file" "s3_endpoint_policy" {
#   template = file("${path.module}/templates/s3_endpoint_policy.json")

#   vars = {
#     bucket_arn = aws_s3_bucket.lab_data.arn
#     region     = data.aws_region.current.name
#   }
# }

locals {
  vpc_ids = {
    east = { for k, v in module.east_vpcs : k => v.vpc_id }
  }
  vpc_cidrs = {
    east = { for k, v in module.east_vpcs : k => v.vpc_cidr }
  }
  inet_gw_ids = {
    east = { for k, v in module.east_vpcs : k => v.inet_gw_id }
  }
  public_subnet_ids = {
    east = { for k, v in module.east_vpcs : k => v.public_subnet_ids }
  }
  public_route_table_ids = {
    east = { for k, v in module.east_vpcs : k => v.public_route_table_ids }
  }
  private_subnet_ids = {
    east = { for k, v in module.east_vpcs : k => v.private_subnet_ids }
  }
  private_route_table_ids = {
    east = { for k, v in module.east_vpcs : k => v.private_route_table_ids }
  }
  intra_subnet_ids = {
    east = { for k, v in module.east_vpcs : k => v.intra_subnet_ids }
  }
  intra_route_table_ids = {
    east = { for k, v in module.east_vpcs : k => v.intra_route_table_ids }
  }
}

# output "vpcs" {
#   value = local.vpcs
# }
output "vpc_ids" {
  value = local.vpc_ids
}
# output "vpc_cidrs" {
#   value = local.vpc_cidrs
# }
# output "inet_gw_ids" {
#   value = local.inet_gw_ids
# }
# output "public_subnet_ids" {
#   value = local.public_subnet_ids
# }
# output "public_route_table_ids" {
#   value = local.public_route_table_ids
# }

locals {
  vpc_info = {
    east = {
      hub1 = {
        vpc_cidr                         = var.vpc_cidrs.east["hub1"]
        instance_tenancy                 = "default"
        enable_dns_hostnames             = true
        enable_dns_support               = true
        enable_classiclink               = false
        enable_classiclink_dns_support   = false
        assign_generated_ipv6_cidr_block = false
        create_inet_gw                   = true
        num_nat_gw                       = 1

        public_subnets = {
          cidr_blocks = [
            cidrsubnet(var.vpc_cidrs.east["hub1"], 8, 0),
            cidrsubnet(var.vpc_cidrs.east["hub1"], 8, 1),
          ]
          availability_zones      = ["us-east-1c", "us-east-1d"]
          map_public_ip_on_launch = true
        }
        public_route_table = {
          tags = {
            Purpose = "Route to internet and other public services."
          }
        }
        private_subnets = {
          cidr_blocks = [
            cidrsubnet(var.vpc_cidrs.east["hub1"], 8, 64),
            cidrsubnet(var.vpc_cidrs.east["hub1"], 8, 65),
          ]
        }
        intra_subnets = {
          cidr_blocks = [
            cidrsubnet(var.vpc_cidrs.east["hub1"], 8, 128),
            cidrsubnet(var.vpc_cidrs.east["hub1"], 8, 129),
          ]
        }
      }
      spoke1 = {
        vpc_cidr                         = var.vpc_cidrs.east["spoke1"]
        instance_tenancy                 = "default"
        enable_dns_hostnames             = true
        enable_dns_support               = true
        enable_classiclink               = false
        enable_classiclink_dns_support   = false
        assign_generated_ipv6_cidr_block = false

        intra_subnets = {
          cidr_blocks = [
            cidrsubnet(var.vpc_cidrs.east["spoke1"], 8, 128),
            cidrsubnet(var.vpc_cidrs.east["spoke1"], 8, 129),
          ]
        }
      }
      spoke2 = {
        vpc_cidr                         = var.vpc_cidrs.east["spoke2"]
        instance_tenancy                 = "default"
        enable_dns_hostnames             = true
        enable_dns_support               = true
        enable_classiclink               = false
        enable_classiclink_dns_support   = false
        assign_generated_ipv6_cidr_block = false

        intra_subnets = {
          cidr_blocks = [
            cidrsubnet(var.vpc_cidrs.east["spoke2"], 8, 128),
            cidrsubnet(var.vpc_cidrs.east["spoke2"], 8, 129),
          ]
        }
      }
      spoke3 = {
        vpc_cidr                         = var.vpc_cidrs.east["spoke3"]
        instance_tenancy                 = "default"
        enable_dns_hostnames             = true
        enable_dns_support               = true
        enable_classiclink               = false
        enable_classiclink_dns_support   = false
        assign_generated_ipv6_cidr_block = false

        intra_subnets = {
          cidr_blocks = [
            cidrsubnet(var.vpc_cidrs.east["spoke3"], 8, 128)
          ]
        }
      }
    }
  }
}

module "east_vpcs" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  for_each  = local.vpc_info.east
  name      = "east-${each.key}"
  vpc       = each.value
  inet_gw = {
    tags = {
      Purpose = "Route stuff to the internet"
    }
  }
  nat_gw = {
    tags = {
      Purpose = "Route private stuff to the internet"
    }
  }
  public_subnets     = lookup(each.value, "public_subnets", {})
  public_route_table = lookup(each.value, "public_route_table", {})
  private_subnets    = lookup(each.value, "private_subnets", {})
  intra_subnets      = lookup(each.value, "intra_subnets", {})

  vpc_endpoints = {
    s3 = {
      endpoint_type = "Gateway"
      service_type  = "s3"
    }
  }
}

locals {
  route_info = {
    east = {
      test = {
        destination_cidr_block = "10.0.0.0/8"
        gateway_id             = local.inet_gw_ids.east["hub1"][0]
        route_table_id         = local.public_route_table_ids.east["hub1"][0]
      }
    }
  }
}

resource "aws_route" "east_routes" {
  for_each               = local.route_info.east
  route_table_id         = each.value["route_table_id"]
  destination_cidr_block = lookup(each.value, "destination_cidr_block", null)
  gateway_id             = lookup(each.value, "gateway_id", null)
}

# module "east_tgw" {
#   source     = "../../modules/transit-gateway"
#   providers  = { aws = aws.us_east_1 }
#   create_tgw = true
#   name       = "east-tgw"

#   vpc_attachments = {
#     hub1 = {
#       vpc_id               = local.vpcs.east.hubs["hub1"].id
#       subnet_ids           = local.private_subnets.east.hubs["hub1"][*].id
#       default_asssociation = false
#       default_propagation  = false
#       tags = {
#         Purpose = "Attachment to hub VPC"
#       }
#     },
#     spoke1 = {
#       vpc_id               = local.vpcs.east.spokes["spoke1"].id
#       subnet_ids           = local.intra_subnets.east.spokes["spoke1"][*].id
#       default_asssociation = false
#       default_propagation  = false
#     },
#     spoke2 = {
#       vpc_id               = local.vpcs.east.spokes["spoke2"].id
#       subnet_ids           = local.intra_subnets.east.spokes["spoke2"][*].id
#       default_asssociation = false
#       default_propagation  = false
#     },
#     spoke3 = {
#       vpc_id               = local.vpcs.east.spokes["spoke3"].id
#       subnet_ids           = local.intra_subnets.east.spokes["spoke3"][*].id
#       default_asssociation = false
#       default_propagation  = false
#     },
#   }

#   route_tables = {
#     hubs = {
#       tags = { Purpose = "RT attached to hub1 VPC" }
#     }
#     spokes = {
#       tags = { Purpose = "RT attached to spoke VPC" }
#     }
#   }

#   route_table_associations = {
#     hub1   = { route_table_name = "hubs" }
#     spoke1 = { route_table_name = "spokes" }
#     spoke2 = { route_table_name = "spokes" }
#     spoke3 = { route_table_name = "spokes" }
#   }

#   route_table_propagations = {
#     hub_to_spokes = {
#       attach_name      = "hub1"
#       route_table_name = "spokes"
#     }
#     spoke_1_to_hub = {
#       attach_name      = "spoke1"
#       route_table_name = "hubs"
#     }
#     spoke_2_to_hub = {
#       attach_name      = "spoke2"
#       route_table_name = "hubs"
#     }
#     spoke_3_to_hub = {
#       attach_name      = "spoke3"
#       route_table_name = "hubs"
#     }
#     spoke_1_to_2 = {
#       attach_name      = "spoke1"
#       route_table_name = "spokes"
#     }
#     spoke_2_to_1 = {
#       attach_name      = "spoke2"
#       route_table_name = "spokes"
#     }
#   }

#   tgw_routes = {
#     spoke_default = {
#       destination      = "0.0.0.0/0"
#       attach_id        = "hub1"
#       route_table_name = "spokes"
#     }
#     blackhole_1 = {
#       destination      = "10.0.0.0/8"
#       blackhole        = true
#       route_table_name = "hubs"
#     }
#     blackhole_2 = {
#       destination      = "10.0.0.0/8"
#       blackhole        = true
#       route_table_name = "spokes"
#     }
#     blackhole_3 = {
#       destination      = "172.16.0.0/12"
#       blackhole        = true
#       route_table_name = "hubs"
#     }
#     blackhole_4 = {
#       destination      = "172.16.0.0/12"
#       blackhole        = true
#       route_table_name = "spokes"
#     }
#     blackhole_5 = {
#       destination      = "192.168.0.0/16"
#       blackhole        = true
#       route_table_name = "hubs"
#     }
#     blackhole_6 = {
#       destination      = "192.168.0.0/16"
#       blackhole        = true
#       route_table_name = "spokes"
#     }
#   }
# }

# module "east_ec2" {
#   source        = "../../modules/ec2"
#   providers     = { aws = aws.us_east_1 }
#   name          = "east-ec2"
#   key_name      = "aws-test-key"
#   priv_key      = module.ssh_key.priv_key
#   priv_key_path = var.priv_key_path

#   craate_custom_eni = true
#   custom_eni_props = {
#     hub1_public1 = {
#       subnet_id       = local.public_subnets.east.hubs["hub1"][0].id
#       security_groups = null
#       private_ips     = [cidrhost(local.public_subnets.east.hubs["hub1"][0].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#     spoke1_intra1 = {
#       subnet_id       = local.intra_subnets.east.spokes["spoke1"][0].id
#       security_groups = null
#       private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke1"][0].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#     spoke1_intra2 = {
#       subnet_id       = local.intra_subnets.east.spokes["spoke1"][1].id
#       security_groups = null
#       private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke1"][1].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#     spoke2_intra1 = {
#       subnet_id       = local.intra_subnets.east.spokes["spoke2"][0].id
#       security_groups = null
#       private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke2"][0].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#     spoke2_intra2 = {
#       subnet_id       = local.intra_subnets.east.spokes["spoke2"][1].id
#       security_groups = null
#       private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke2"][1].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#     spoke3_intra1 = {
#       subnet_id       = local.intra_subnets.east.spokes["spoke3"][0].id
#       security_groups = null
#       private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke3"][0].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#     spoke3_intra2 = {
#       subnet_id       = local.intra_subnets.east.spokes["spoke3"][1].id
#       security_groups = null
#       private_ips     = [cidrhost(local.intra_subnets.east.spokes["spoke3"][1].cidr_block, 10)]
#       tags = {
#         Attach = "For HUB1 Public ENI"
#       }
#     }
#   }
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
