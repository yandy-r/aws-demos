module "ssh_key" {
  source        = "../../modules/ssh-key"
  key_name      = var.key_name
  priv_key_path = var.priv_key_path
}

module "east_data" {
  source             = "./data"
  providers          = { aws = aws.us_east_1 }
  get_amzn_ami       = true
  key_name           = var.key_name
  priv_key_path      = var.priv_key_path
  instance_hostnames = ["hub_bastion1"]

  depends_on = [
    module.ssh_key
  ]
}

locals {
  east_s3_endpoint_policy = module.east_data.s3_endpoint_policy
  amzn_ami                = module.east_data.amzn_ami
  amzn_cloud_config       = module.east_data.amzn_cloud_config
  ubuntu_ami              = module.east_data.ubuntu_ami
  ubuntu_cloud_config     = module.east_data.ubuntu_cloud_config
}

# locals {
#   east_vpcs = {
#     hub1 = {


#       security_groups = {
#         public1 = {
#           egress = [
#             {
#               description      = "Allow all out"
#               from_port        = 0
#               to_port          = 0
#               protocol         = "-1"
#               cidr_blocks      = ["0.0.0.0/0"]
#               ipv6_cidr_blocks = ["::/0"]
#             }
#           ]
#           ingress = [
#             {
#               description = "Allow ALL sourced from self"
#               from_port   = 0
#               to_port     = 0
#               protocol    = "-1"
#               self        = true
#             },
#             {
#               description = "Allow ICMP from home"
#               from_port   = -1
#               to_port     = -1
#               protocol    = "icmp"
#               cidr_blocks = [var.self_public_ip]
#             },
#             {
#               description = "Allow SSH from home"
#               from_port   = 22
#               to_port     = 22
#               protocol    = "tcp"
#               cidr_blocks = [var.self_public_ip]
#             }
#           ]
#         }
#         private1 = {
#           ingress = [
#             {
#               description = "Allow ALL sourced from self"
#               from_port   = 0
#               to_port     = 0
#               protocol    = "-1"
#               self        = true
#             }
#           ]
#           egress = [
#             {
#               description      = "Allow all out"
#               from_port        = 0
#               to_port          = 0
#               protocol         = "-1"
#               cidr_blocks      = ["0.0.0.0/0"]
#               ipv6_cidr_blocks = ["::/0"]
#             }
#           ]
#         }
#         intra1 = {
#           ingress = [
#             {
#               description = "Allow ALL sourced from self"
#               from_port   = 0
#               to_port     = 0
#               protocol    = "-1"
#               self        = true
#             }
#           ]
#           egress = [
#             {
#               description      = "Allow all out"
#               from_port        = 0
#               to_port          = 0
#               protocol         = "-1"
#               cidr_blocks      = ["0.0.0.0/0"]
#               ipv6_cidr_blocks = ["::/0"]
#             }
#           ]
#         }
#       }
#     }

#     security_groups = {
#       intra1 = {
#         ingress = [
#           {
#             description = "Allow ALL sourced from self"
#             from_port   = 0
#             to_port     = 0
#             protocol    = "-1"
#             self        = true
#           }
#         ]
#         egress = [
#           {
#             description      = "Allow all out"
#             from_port        = 0
#             to_port          = 0
#             protocol         = "-1"
#             cidr_blocks      = ["0.0.0.0/0"]
#             ipv6_cidr_blocks = ["::/0"]
#           }
#         ]
#       }
#     }
#   }

#   intra_subnets = {
#     intra1 = { cidr_block = "10.202.128.0/24", availability_zone = "us-east-1a" }
#     intra2 = { cidr_block = "10.202.129.0/24", availability_zone = "us-east-1b" }
#   }

#   security_groups = {
#     intra1 = {
#       ingress = [
#         {
#           description = "Allow ALL sourced from self"
#           from_port   = 0
#           to_port     = 0
#           protocol    = "-1"
#           self        = true
#         }
#       ]
#       egress = [
#         {
#           description      = "Allow all out"
#           from_port        = 0
#           to_port          = 0
#           protocol         = "-1"
#           cidr_blocks      = ["0.0.0.0/0"]
#           ipv6_cidr_blocks = ["::/0"]
#         }
#       ]
#     }
#   }
# }
# intra_subnets = {
#   intra1 = { cidr_block = "10.203.128.0/24" }
# }

# security_groups = {
#   intra1 = {
#     ingress = [
#       {
#         description = "Allow ALL sourced from self"
#         from_port   = 0
#         to_port     = 0
#         protocol    = "-1"
#         self        = true
#       }
#     ]
#     egress = [
#       {
#         description      = "Allow all out"
#         from_port        = 0
#         to_port          = 0
#         protocol         = "-1"
#         cidr_blocks      = ["0.0.0.0/0"]
#         ipv6_cidr_blocks = ["::/0"]
#       }
#     ]
#   }
# }

locals {
  east = {
    input = {
      vpcs = {
        hub1 = {
          vpc = [{
            name                             = "east-hub"
            cidr_block                       = var.cidr_blocks.east["hub1"]
            instance_tenancy                 = "default"
            enable_dns_hostnames             = true
            enable_dns_support               = true
            enable_classiclink               = false
            enable_classiclink_dns_support   = false
            assign_generated_ipv6_cidr_block = false
          }],
          internet_gateway = [{}]
          nat_gateway      = [{}]

          public_subnets = [
            {
              name                    = "hub-public-1"
              cidr_block              = "10.200.0.0/24"
              availability_zone       = "us-east-1a"
              map_public_ip_on_launch = true
            },
            {
              name                    = "hub-public-2"
              cidr_block              = "10.200.1.0/24"
              availability_zone       = "us-east-1b"
              map_public_ip_on_launch = true
            }
          ]
          public_route_table = [{
            name = "hub-public-1"
          }]

          private_subnets = [
            {
              name              = "hub-private-1"
              cidr_block        = "10.200.64.0/24",
              availability_zone = "us-east-1a"
            },
            {
              name              = "hub-private-2"
              cidr_block        = "10.200.65.0/24",
              availability_zone = "us-east-1b"
            }
          ]
          private_route_table = [{
            name = "hub-private-1"
          }]

          intra_subnets = [
            {
              name              = "hub-intra-1"
              cidr_block        = "10.200.128.0/24",
              availability_zone = "us-east-1a"
            },
            {
              name              = "hub-intra-2"
              cidr_block        = "10.200.129.0/24",
              availability_zone = "us-east-1b"
            }
          ]
          intra_route_table = [{
            name = "hub-intra-1"
          }]

          vpc_endpoints = [{
            endpoint_type   = "Gateway"
            service_type    = "s3"
            policy          = local.east_s3_endpoint_policy
            route_table_ids = ""
            tags = {
              Name = "hub-s3-endpoint"
            }
          }]
        }
        spoke1 = {
          vpc = [{
            name                             = "spoke1"
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
              name              = "spoke1-intra-1"
              cidr_block        = "10.201.128.0/24",
              availability_zone = "us-east-1a"
            },
            {
              name              = "spoke1-intra-2"
              cidr_block        = "10.201.129.0/24",
              availability_zone = "us-east-1b"
            },
          ]
          intra_route_table = [{
            name = "spoke1-intra-1"
          }]
        }
        spoke2 = {
          vpc = [{
            name                             = "spoke2"
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
              name              = "spoke2-intra-1"
              cidr_block        = "10.202.128.0/24",
              availability_zone = "us-east-1a"
            },
            {
              name              = "spoke2-intra-2"
              cidr_block        = "10.202.129.0/24",
              availability_zone = "us-east-1b"
            }
          ]
          intra_route_table = [{
            name = "spoke2-intra-1"
          }]
        }
        spoke3 = {
          vpc = [{
            name                             = "spoke3"
            cidr_block                       = var.cidr_blocks.east["spoke3"]
            instance_tenancy                 = "default"
            enable_dns_hostnames             = true
            enable_dns_support               = true
            enable_classiclink               = false
            enable_classiclink_dns_support   = false
            assign_generated_ipv6_cidr_block = false
          }]
          intra_subnets = [{
            name              = "spoke3-intra-1"
            cidr_block        = "10.203.128.0/24",
            availability_zone = "us-east-1a"
            route_table_idx   = 0
          }]
          intra_route_table = [{
            name = "spoke3-intra-1"
          }]
        }
      }
    }
    #   output = {
    #     vpc_ids                = [for k, v in module.east_vpcs.vpc_id : v]
    #     public_route_table_ids = [for v in module.east_vpcs.public_route_table_id : v]
    #     route_table_ids        = [for v in module.east_vpcs.route_table_ids : v]
    #   }
  }
}

# output "vpc_ids" {
#   value = local.east.output.vpc_ids
# }
# output "route_table_ids" {
#   value = local.east.output.route_table_ids
# }
# output "public_route_table_ids" {
#   value = local.east.output.public_route_table_ids
# }
module "east_vpcs" {
  source              = "../../modules/vpc"
  providers           = { aws = aws.us_east_1 }
  for_each            = { for k, v in local.east.input.vpcs : k => v }
  name                = "east"
  vpc                 = lookup(each.value, "vpc", {})
  public_subnets      = lookup(each.value, "public_subnets", {})
  public_route_table  = lookup(each.value, "public_route_table", {})
  private_subnets     = lookup(each.value, "private_subnets", {})
  private_route_table = lookup(each.value, "private_route_table", {})
  intra_subnets       = lookup(each.value, "intra_subnets", {})
  intra_route_table   = lookup(each.value, "intra_route_table", {})
  internet_gateway    = lookup(each.value, "internet_gateway", {})
  nat_gateway         = lookup(each.value, "nat_gateway", {})
}

# locals {
#   east_transit_gateways = {
#     central_east = {
#       dns_support                     = "enable"
#       description                     = "US East Transit Gateway"
#       amazon_side_asn                 = 65000
#       vpn_ecmp_support                = "enable"
#       auto_accept_shared_attachments  = "disable"
#       default_route_table_association = "disable"
#       default_route_table_propagation = "disable"
#       tags                            = { Purpose = "Central routing hub for the east" }

#       vpc_attachments = {
#         hub1 = {
#           vpc_id                                          = local.vpc_ids.east["hub1"]
#           subnet_ids                                      = local.private_subnet_ids.east["hub1"]
#           dns_support                                     = "enable"
#           ipv6_support                                    = "disable"
#           appliance_mode_support                          = "disable"
#           transit_gateway_default_route_table_association = false
#           transit_gateway_default_route_table_propagation = false
#           tags                                            = { Purpose = "Attachment to Hub1 VPC" }
#         }
#         spoke1 = {
#           vpc_id     = local.vpc_ids.east["spoke1"]
#           subnet_ids = local.intra_subnet_ids.east["spoke1"]
#         }
#         spoke2 = {
#           vpc_id     = local.vpc_ids.east["spoke2"]
#           subnet_ids = local.intra_subnet_ids.east["spoke2"]
#         }
#         spoke3 = {
#           vpc_id     = local.vpc_ids.east["spoke3"]
#           subnet_ids = local.intra_subnet_ids.east["spoke3"]
#         }
#       }

#       route_tables = {
#         hubs   = {}
#         spokes = {}
#       }

#       route_table_associations = {
#         hub1   = { route_table_name = "hubs" }
#         spoke1 = { route_table_name = "spokes" }
#         spoke2 = { route_table_name = "spokes" }
#         spoke3 = { route_table_name = "spokes" }
#       }

#       route_table_propagations = {
#         hub_to_spokes = {
#           attach_name      = "hub1"
#           route_table_name = "spokes"
#         }
#         spoke_1_to_hub = {
#           attach_name      = "spoke1"
#           route_table_name = "hubs"
#         }
#         spoke_2_to_hub = {
#           attach_name      = "spoke2"
#           route_table_name = "hubs"
#         }
#         spoke_3_to_hub = {
#           attach_name      = "spoke3"
#           route_table_name = "hubs"
#         }
#         spoke_1_to_2 = {
#           attach_name      = "spoke1"
#           route_table_name = "spokes"
#         }
#         spoke_2_to_1 = {
#           attach_name      = "spoke2"
#           route_table_name = "spokes"
#         }
#       }

#       transit_gateway_routes = {
#         spoke_default = {
#           destination      = "0.0.0.0/0"
#           attach_name      = "hub1"
#           route_table_name = "spokes"
#         }
#         blackhole_1 = {
#           destination      = "10.0.0.0/8"
#           blackhole        = true
#           route_table_name = "hubs"
#         }
#         blackhole_2 = {
#           destination      = "10.0.0.0/8"
#           blackhole        = true
#           route_table_name = "spokes"
#         }
#         blackhole_3 = {
#           destination      = "172.16.0.0/12"
#           blackhole        = true
#           route_table_name = "hubs"
#         }
#         blackhole_4 = {
#           destination      = "172.16.0.0/12"
#           blackhole        = true
#           route_table_name = "spokes"
#         }
#         blackhole_5 = {
#           destination      = "192.168.0.0/16"
#           blackhole        = true
#           route_table_name = "hubs"
#         }
#         blackhole_6 = {
#           destination      = "192.168.0.0/16"
#           blackhole        = true
#           route_table_name = "spokes"
#         }
#       }
#     }
#   }
# }

# module "east_transit_gateway" {
#   source                   = "../../modules/transit-gateway"
#   providers                = { aws = aws.us_east_1 }
#   for_each                 = local.east_transit_gateways
#   transit_gateway          = each.value
#   name                     = each.key
#   vpc_attachments          = lookup(each.value, "vpc_attachments", {})
#   route_tables             = lookup(each.value, "route_tables", {})
#   route_table_associations = lookup(each.value, "route_table_associations", {})
#   route_table_propagations = lookup(each.value, "route_table_propagations", {})
#   transit_gateway_routes   = lookup(each.value, "transit_gateway_routes", {})
# }

# locals {
#   routes = {
#     east = {
#       east_public_test = {
#         destination_cidr_block = "10.0.0.0/8"
#         gateway_id             = local.internet_gateway_ids.east["hub1"]
#         route_table_id         = local.public_route_table_ids.east["hub1"]
#       }
#     }
#   }
# }

# resource "aws_route" "east_routes" {
#   provider               = aws.us_east_1
#   for_each               = local.routes.east
#   route_table_id         = each.value["route_table_id"]
#   destination_cidr_block = lookup(each.value, "destination_cidr_block", null)
#   gateway_id             = lookup(each.value, "gateway_id", null)
# }

# locals {
#   network_interface_ids = {
#     east = { for k, v in module.east_ec2.network_interface_ids : k => v }
#   }
# }
# module "east_ec2" {
#   source    = "../../modules/ec2"
#   providers = { aws = aws.us_east_1 }
#   name      = "east-ec2"
#   key_name  = var.key_name
#   priv_key  = module.ssh_key.priv_key

#   network_interfaces = {
#     hub_bastion1 = {
#       source_dest_check = true
#       subnet_id         = local.public_subnet_ids.east["hub1"][0]
#       private_ips       = ["10.200.0.10"]
#       security_groups   = [local.security_group_ids.east.hub1["public1"]]
#       description       = "Bastion 1 Public Interface"
#       tags              = { Purpose = "Bastion 1 Public Interface" }
#     }
#   }

#   aws_instances = {
#     hub_bastion1 = {
#       ami           = local.amzn_ami
#       instance_type = "t3.medium"
#       user_data     = local.amzn_cloud_config[0]
#       network_interface = [{
#         network_interface_id = local.network_interface_ids.east["hub_bastion1"]
#         device_index         = 0
#       }]
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
