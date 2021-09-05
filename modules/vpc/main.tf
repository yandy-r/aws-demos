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

resource "aws_vpc" "this" {
  for_each                         = { for k, v in var.vpc : k => v }
  cidr_block                       = each.value["cidr_block"]
  instance_tenancy                 = lookup(each.value, "instance_tenancy", "default")
  enable_dns_hostnames             = lookup(each.value, "enable_dns_hostnames", true)
  enable_dns_support               = lookup(each.value, "enable_dns_support", true)
  enable_classiclink               = lookup(each.value, "enable_classiclink", false)
  enable_classiclink_dns_support   = lookup(each.value, "enable_classiclink_dns_support", false)
  assign_generated_ipv6_cidr_block = lookup(each.value, "assign_generated_ipv6_cidr_block", false)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

locals {
  azs                    = data.aws_availability_zones.azs
  vpc_id                 = { for k, v in aws_vpc.this : k => v.id }
  cidr_block             = { for k, v in aws_vpc.this : k => v.cidr_block }
  internet_gateway_id    = [for v in aws_internet_gateway.this : v.id]
  nat_gateway_id         = [for v in aws_nat_gateway.this : v.id]
  intra_subnet_ids       = [for v in aws_subnet.intra : v.id]
  public_subnet_ids      = [for v in aws_subnet.public : v.id]
  private_subnet_ids     = [for v in aws_subnet.private : v.id]
  public_route_table_id  = [for v in aws_route_table.public : v.id]
  private_route_table_id = [for v in aws_route_table.private : v.id]
  intra_route_table_id   = [for v in aws_route_table.intra : v.id]
  route_table_ids        = flatten([local.public_route_table_id[*], local.private_route_table_id[*], local.intra_route_table_id[*]])
  security_group_ids     = { for k, v in aws_security_group.this : k => v.id }
}

resource "aws_internet_gateway" "this" {
  for_each = { for k, v in var.internet_gateway : k => v }
  vpc_id   = lookup(each.value, "vpc_id", local.vpc_id[each.key])

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "inetgw-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_eip" "nat" {
  for_each = { for k, v in var.nat_gateway : k => v }
  vpc      = true

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "nat_eip-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_nat_gateway" "this" {
  for_each      = { for k, v in var.nat_gateway : k => v }
  allocation_id = lookup(each.value, "allocation_id", aws_eip.nat[each.key].id)
  subnet_id     = element([for v in aws_subnet.public : v.id], each.key)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "natgw-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )

  depends_on = [aws_internet_gateway.this]
}

resource "random_shuffle" "subnet_azs" {
  input        = local.azs.names
  result_count = length(local.azs.names)
}
resource "random_integer" "this" {
  min = 1
  max = length(local.azs.names) - 1
}
resource "aws_subnet" "public" {
  for_each                = { for k, v in var.public_subnets : k => v }
  vpc_id                  = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)
  cidr_block              = each.value["cidr_block"]
  availability_zone       = lookup(each.value, "availability_zone", true) != true ? each.value["availability_zone"] : random_shuffle.subnet_azs.result[random_integer.this.result]
  map_public_ip_on_launch = lookup(each.value, "map_public_ip_on_launch", true)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "public-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table" "public" {
  for_each = { for k, v in var.public_route_table : k => v }
  vpc_id   = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "public-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table_association" "public" {
  for_each       = { for k, v in var.public_subnets : k => v }
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = lookup(each.value, "route_table_id", aws_route_table.public[each.value.route_table_idx].id)
}

resource "aws_subnet" "private" {
  for_each                = { for k, v in var.private_subnets : k => v }
  vpc_id                  = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)
  cidr_block              = each.value["cidr_block"]
  availability_zone       = lookup(each.value, "availability_zone", true) != true ? each.value["availability_zone"] : random_shuffle.subnet_azs.result[random_integer.this.result]
  map_public_ip_on_launch = lookup(each.value, "map_public_ip_on_launch", true)

  tags = merge(
    {
      Name = lookup(each.value, "name", "${var.name}-private-${each.key}")
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table" "private" {
  for_each = { for k, v in var.private_route_table : k => v }
  vpc_id   = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "private-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table_association" "private" {
  for_each       = { for k, v in var.private_subnets : k => v }
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = lookup(each.value, "route_table_id", aws_route_table.private[each.value.route_table_idx].id)
}

resource "aws_subnet" "intra" {
  for_each                = { for k, v in var.intra_subnets : k => v }
  vpc_id                  = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)
  cidr_block              = each.value["cidr_block"]
  availability_zone       = lookup(each.value, "availability_zone", true) != true ? each.value["availability_zone"] : random_shuffle.subnet_azs.result[random_integer.this.result]
  map_public_ip_on_launch = lookup(each.value, "map_public_ip_on_launch", false)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "intra-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table" "intra" {
  for_each = { for k, v in var.intra_route_table : k => v }
  vpc_id   = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "intra-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table_association" "intra" {
  for_each       = { for k, v in var.intra_subnets : k => v }
  subnet_id      = aws_subnet.intra[each.key].id
  route_table_id = lookup(each.value, "route_table_id", aws_route_table.intra[each.value.route_table_idx].id)
}

resource "aws_route" "internet_gateway_default" {
  for_each               = { for k, v in aws_internet_gateway.this : k => v }
  route_table_id         = lookup(each.value, "route_table_id", aws_route_table.public[each.key].id)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = lookup(each.value, "internet_gateway_id", aws_internet_gateway.this[0].id)
}

resource "aws_route" "nat_gateway_default" {
  for_each               = { for k, v in var.nat_gateway : k => v }
  route_table_id         = lookup(each.value, "route_table_id", aws_route_table.private[each.key].id)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = lookup(each.value, "nat_gateway_id", aws_nat_gateway.this[each.key].id)
}

resource "aws_route" "this" {
  for_each                  = var.routes
  route_table_id            = lookup(each.value, "route_table_id", null)
  destination_cidr_block    = lookup(each.value, "destination_cidr_block", null)
  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  instance_id               = lookup(each.value, "instance_id", null)
  local_gateway_id          = lookup(each.value, "local_gateway_id", null)
  vpc_endpoint_id           = lookup(each.value, "vpc_endpoint_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  carrier_gateway_id        = lookup(each.value, "carrier_gateway_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
  egress_only_gateway_id    = lookup(each.value, "egress_only_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
}

data "aws_region" "current" {}
resource "aws_vpc_endpoint" "this" {
  for_each          = { for k, v in var.vpc_endpoints : k => v }
  vpc_id            = lookup(each.value, "vpc_id", aws_vpc.this[each.value.vpc_idx].id)
  vpc_endpoint_type = lookup(each.value, "endpoint_type", "Gateway")
  service_name      = lookup(each.value, "service_name", "com.amazonaws.${data.aws_region.current.name}.${each.value["service_type"]}")
  policy            = lookup(each.value, "policy", null)
  route_table_ids   = lookup(each.value, "route_table_ids", [])

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "endpoint-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

# ### -------------------------------------------------------------------------------------------- ###
# ### SECURITY GROUPS
# ### -------------------------------------------------------------------------------------------- ###

resource "aws_security_group" "this" {
  for_each    = var.security_groups
  description = lookup(each.value, "description", null)
  vpc_id      = lookup(each.value, "vpc_id", local.vpc_id)

  egress = [for v in lookup(each.value, "egress", []) : {
    from_port        = v["from_port"]
    to_port          = v["to_port"]
    protocol         = v["protocol"]
    self             = lookup(v, "self", null)
    description      = lookup(v, "description", null)
    cidr_blocks      = lookup(v, "cidr_blocks", null)
    ipv6_cidr_blocks = lookup(v, "ipv6_cidr_blocks", null)
    prefix_list_ids  = lookup(v, "prefix_list_ids", null)
    security_groups  = lookup(v, "security_groups", null)
    }
  ]

  ingress = [for v in lookup(each.value, "ingress", []) : {
    from_port        = v["from_port"]
    to_port          = v["to_port"]
    protocol         = v["protocol"]
    self             = lookup(v, "self", null)
    description      = lookup(v, "description", null)
    cidr_blocks      = lookup(v, "cidr_blocks", null)
    ipv6_cidr_blocks = lookup(v, "ipv6_cidr_blocks", null)
    prefix_list_ids  = lookup(v, "prefix_list_ids", null)
    security_groups  = lookup(v, "security_groups", null)
    }
  ]

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

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
