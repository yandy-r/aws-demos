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

### -------------------------------------------------------------------------------------------- ###
### VPCS
### -------------------------------------------------------------------------------------------- ###

data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  azs = data.aws_availability_zones.azs
}

resource "aws_vpc" "this" {
  count                            = length(var.vpc) > 0 ? 1 : 0
  cidr_block                       = var.vpc["vpc_cidr"]
  instance_tenancy                 = lookup(var.vpc, "instance_tenancy", "default")
  enable_dns_hostnames             = lookup(var.vpc, "enable_dns_hostnames", true)
  enable_dns_support               = lookup(var.vpc, "enable_dns_support", true)
  enable_classiclink               = lookup(var.vpc, "enable_classiclink", false)
  enable_classiclink_dns_support   = lookup(var.vpc, "enable_classiclink_dns_support", false)
  assign_generated_ipv6_cidr_block = lookup(var.vpc, "assign_generated_ipv6_cidr_block", false)

  tags = merge(
    {
      Name = "${var.name}-${count.index + 1}"
    },
    var.tags,
    lookup(var.vpc, "tags", null)
  )
}

locals {
  vpc                    = element(aws_vpc.this[*], 0)
  vpc_id                 = element(aws_vpc.this[*].id, 0)
  vpc_cidr               = element(aws_vpc.this[*].cidr_block, 0)
  inet_gw_id             = aws_internet_gateway.this[*].id
  public_subnet_ids      = aws_subnet.public[*].id
  public_route_table_ids = aws_route_table.public[*].id
}

resource "aws_internet_gateway" "this" {
  count  = var.create_inet_gw ? 1 : 0
  vpc_id = lookup(var.inet_gw, "vpc_id", local.vpc_id)

  tags = merge(
    {
      Name = "${var.name}"
    },
    var.tags,
    lookup(var.inet_gw, "tags", null)
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets.cidr_blocks) > 0 ? length(var.public_subnets.cidr_blocks) : 0
  vpc_id                  = lookup(var.public_subnets, "vpc_id", local.vpc_id)
  cidr_block              = var.public_subnets.cidr_blocks[count.index]
  availability_zone       = lookup(var.public_subnets, "availability_zones", true) != true ? var.public_subnets.availability_zones[count.index] : local.azs.names[count.index]
  map_public_ip_on_launch = lookup(var.public_subnets, "map_public_ip_on_launch", true)

  tags = merge(
    {
      Name = "${var.name}-public-${count.index + 1}"
    },
    var.tags,
    lookup(var.public_subnets, "tags", null)
  )
}

resource "aws_route_table" "public" {
  count  = length(var.public_subnets.cidr_blocks) > 0 ? 1 : 0
  vpc_id = lookup(var.public_route_table, "vpc_id", local.vpc_id)

  tags = merge(
    {
      Name = "${var.name}-public-${count.index + 1}"
    },
    var.tags,
    lookup(var.public_route_table, "tags", null)
  )
}

# resource "aws_route_table_association" "public" {
#   for_each       = aws_subnet.public
#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.public[0].id
# }

# resource "aws_subnet" "private" {
#   count                   = length(var.private_subnets) > 0 && (length(var.private_subnets) <= length(local.azs)) ? length(var.private_subnets) : 0
#   vpc_id                  = aws_vpc.this[0].id
#   cidr_block              = var.private_subnets[count.index]
#   availability_zone       = length(regexall("^[a-z]{2}-", var.azs[count.index])) > 0 ? var.azs[count.index] : null
#   map_public_ip_on_launch = false

#   tags = merge(
#     {
#       Name = "${var.name}-private-${count.index + 1}"
#     },
#     var.tags,
#     var.private_subnet_tags
#   )
# }

# resource "aws_route_table" "private" {
#   count  = var.nat_gateway_count > 0 && (length(var.private_subnets) > 0 && length(var.public_subnets) > 0) ? var.nat_gateway_count : 0
#   vpc_id = aws_vpc.this[0].id

#   route = [
#     {
#       cidr_block                               = "0.0.0.0/0"
#       nat_gateway_id                           = aws_nat_gateway.this[count.index].id
#       carrier_gateway_id                       = null
#       egress_only_gateway_id                   = null
#       destination_prefix_list_id               = null
#       gateway_id                               = null
#       instance_id                              = null
#       ipv6_cidr_block                          = null
#       local_gateway_id                         = null
#       network_interface_id                     = null
#       transit_gateway_id                       = null
#       vpc_endpoint_id                          = null
#       vpc_peering_connection_id                = null
#       carrier_gegress_only_gateway_idateway_id = null
#     }
#   ]

#   tags = merge(
#     {
#       Name = "${var.name}-private-${count.index + 1}"
#     },
#     var.tags,
#     var.private_route_table_tags,
#   )
# }

# resource "aws_route_table_association" "private" {
#   count          = var.nat_gateway_count > 0 && length(var.private_subnets) > 0 ? var.nat_gateway_count : 0
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }

# resource "aws_subnet" "intra" {
#   count = length(var.intra_subnets) > 0 ? length(var.intra_subnets) : 0

#   vpc_id                  = aws_vpc.this[0].id
#   cidr_block              = var.intra_subnets[count.index]
#   availability_zone       = length(regexall("^[a-z]{2}-", var.azs[count.index])) > 0 ? var.azs[count.index] : null
#   availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
#   map_public_ip_on_launch = false

#   tags = merge(
#     {
#       Name = "${var.name}-Intra-${count.index + 1}"
#     },
#     var.tags,
#     var.intra_subnet_tags,
#   )
# }

# resource "aws_route_table" "intra" {
#   count  = length(var.intra_subnets) > 0 ? 1 : 0
#   vpc_id = aws_vpc.this[0].id

#   tags = merge(
#     {
#       Name = "${var.name}-Intra-${count.index + 1}"
#     },
#     var.tags,
#     var.intra_route_table_tags,
#   )
# }

# resource "aws_route_table_association" "intra" {
#   count          = length(var.intra_subnets) > 0 ? 1 : 0
#   subnet_id      = aws_subnet.intra[count.index].id
#   route_table_id = aws_route_table.intra[count.index].id
# }

# resource "aws_eip" "nat" {
#   count = var.nat_gateway_count > 0 && length(var.public_subnets) > 0 ? var.nat_gateway_count : 0

#   vpc = true

#   tags = merge(
#     {
#       Name = "${var.name}-nat_eip-${count.index + 1}"
#     },
#     var.tags,
#     var.nat_eip_tags,
#   )
# }

# resource "aws_nat_gateway" "this" {
#   count = var.nat_gateway_count > 0 && length(var.public_subnets) > 0 ? var.nat_gateway_count : 0

#   allocation_id = aws_eip.nat[count.index].id
#   subnet_id     = aws_subnet.public[count.index].id

#   tags = merge(
#     {
#       Name = "${var.name}-natgw-${count.index + 1}"
#     },
#     var.tags,
#     var.nat_gateway_tags,
#   )

#   depends_on = [aws_internet_gateway.this]
# }

# data "aws_region" "current" {}
# locals {
#   route_table_ids = concat(aws_route_table.public[*].id, aws_route_table.private[*].id, aws_route_table.intra[*].id)
# }
# resource "aws_vpc_endpoint" "this" {
#   for_each          = { for k, v in var.vpc_endpoints : k => v if length(var.vpc_endpoints) > 0 }
#   vpc_id            = lookup(each.value, "vpc_id", aws_vpc.this[0].id)
#   vpc_endpoint_type = lookup(each.value, "endpoint_type", "Gateway")
#   service_name      = lookup(each.value, "service_name", "com.amazonaws.${data.aws_region.current.name}.${each.value["service_type"]}")
#   policy            = lookup(each.value, "policy", null)
#   route_table_ids   = lookup(each.value, "route_table_ids", local.route_table_ids)

#   tags = merge(
#     {
#       Name = "${var.name}-endpoint-${each.key}"
#     },
#     var.tags,
#     lookup(each.value, "tags", null)
#   )
# }

# ### -------------------------------------------------------------------------------------------- ###
# ### SECURITY GROUPS
# ### -------------------------------------------------------------------------------------------- ###

# resource "aws_security_group" "hub_public" {
#   description = "hub instances public SG"
#   vpc_id      = aws_vpc.vpcs.*.id[0]

#   tags = {
#     Name = "hub public"
#   }
# }


# resource "aws_security_group" "hub_private" {
#   description = "hub instances private SG"
#   vpc_id      = aws_vpc.vpcs.*.id[0]

#   tags = {
#     Name = "hub private"
#   }
# }

# locals {
#   hub_rules = {

#     public_egress = {
#       description              = "Allow all outbound"
#       type                     = "egress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["0.0.0.0/0"]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_public.id
#     }

#     public_rule_1 = {
#       description              = "Allow SSH from HOME/Office IP"
#       type                     = "ingress"
#       from_port                = 22
#       to_port                  = 22
#       protocol                 = "tcp"
#       cidr_blocks              = [var.self_public_ip]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_public.id
#     }

#     public_rule_2 = {
#       description              = "Allow ICMP from HOME/Office IP"
#       type                     = "ingress"
#       from_port                = -1
#       to_port                  = -1
#       protocol                 = "icmp"
#       cidr_blocks              = [var.self_public_ip]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_public.id
#     }

#     public_rule_3 = {
#       description              = "Allow ALL from hub private subnet"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       source_security_group_id = aws_security_group.hub_private.id
#       cidr_blocks              = null
#       security_group_id        = aws_security_group.hub_public.id
#     }

#     public_rule_4 = {
#       description              = "Allow ALL from hub public to self"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       source_security_group_id = aws_security_group.hub_public.id
#       cidr_blocks              = null
#       security_group_id        = aws_security_group.hub_public.id
#     }

#     private_egress = {
#       description              = "Allow all outbound"
#       type                     = "egress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["0.0.0.0/0"]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_1 = {
#       description              = "Allow all from spoke VPC 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[1].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_2 = {
#       description              = "Allow all from spoke VPC 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[2].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_3 = {
#       description              = "Allow all from spoke VPC 3"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[3].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_4 = {
#       description              = "Allow ALL from hub public subnet"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       source_security_group_id = aws_security_group.hub_public.id
#       cidr_blocks              = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_5 = {
#       description              = "Allow ALL from hub private (self)"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       source_security_group_id = aws_security_group.hub_private.id
#       cidr_blocks              = null
#       security_group_id        = aws_security_group.hub_private.id
#     }
#   }
# }

# resource "aws_security_group_rule" "hub_rules" {
#   for_each                 = local.hub_rules
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
#   spoke_1_rules = {

#     egress = {
#       description              = "Allow all outbound"
#       type                     = "egress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["0.0.0.0/0"]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_1.id
#     }

#     rule_1 = {
#       description              = "Allow ALL from self"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = null
#       source_security_group_id = aws_security_group.spoke_1.id
#       security_group_id        = aws_security_group.spoke_1.id
#     }

#     rule_2 = {
#       description              = "Allow ALL from hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[0].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_1.id
#     }

#     rule_3 = {
#       description              = "Allow ALL from spoke 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[2].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_1.id
#     }
#   }

#   spoke_2_rules = {

#     egress = {
#       description              = "Allow all outbound"
#       type                     = "egress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["0.0.0.0/0"]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_2.id
#     }

#     rule_1 = {
#       description              = "Allow ALL from self"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = null
#       source_security_group_id = aws_security_group.spoke_2.id
#       security_group_id        = aws_security_group.spoke_2.id
#     }

#     rule_2 = {
#       description              = "Allow ALL from hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[0].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_2.id
#     }

#     rule_3 = {
#       description              = "Allow ALL from spoke 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[1].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_2.id
#     }
#   }

#   spoke_3_rules = {

#     egress = {
#       description              = "Allow all outbound"
#       type                     = "egress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = ["0.0.0.0/0"]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_3.id
#     }

#     rule_1 = {
#       description              = "Allow ALL from self"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = null
#       source_security_group_id = aws_security_group.spoke_3.id
#       security_group_id        = aws_security_group.spoke_3.id
#     }

#     rule_2 = {
#       description              = "Allow ALL from hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[0].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_3.id
#     }
#   }
# }


# resource "aws_security_group_rule" "spoke_1_rules" {
#   for_each                 = local.spoke_1_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }

# resource "aws_security_group_rule" "spoke_2_rules" {
#   for_each                 = local.spoke_2_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }

# resource "aws_security_group_rule" "spoke_3_rules" {
#   for_each                 = local.spoke_3_rules
#   description              = each.value.description
#   type                     = each.value.type
#   from_port                = each.value.from_port
#   to_port                  = each.value.to_port
#   protocol                 = each.value.protocol
#   cidr_blocks              = each.value.cidr_blocks
#   source_security_group_id = each.value.source_security_group_id
#   security_group_id        = each.value.security_group_id
# }

# resource "aws_security_group" "spoke_1" {
#   description = "spoke 1 private"
#   vpc_id      = aws_vpc.vpcs.*.id[1]

#   tags = {
#     Name = "spoke 1"
#   }
# }

# resource "aws_security_group" "spoke_2" {
#   description = "spoke 2 private"
#   vpc_id      = aws_vpc.vpcs.*.id[2]

#   tags = {
#     Name = "spoke 2"
#   }
# }

# resource "aws_security_group" "spoke_3" {
#   description = "spoke 3 private"
#   vpc_id      = aws_vpc.vpcs.*.id[3]

#   tags = {
#     Name = "spoke 3"
#   }
# }

# ### -------------------------------------------------------------------------------------------- ###
# ### S3
# ### -------------------------------------------------------------------------------------------- ###

# resource "aws_s3_bucket" "lab_data" {
#   bucket = var.bucket_name
#   acl    = "private"

#   tags = {
#     Name = "Lab Data"
#   }
# }
