### -------------------------------------------------------------------------------------------- ###
### PROVIDERS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
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
  count                            = var.create_vpc ? 1 : 0
  cidr_block                       = var.vpc_cidr
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_classiclink               = var.enable_classiclink
  enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(
    {
      Name = "${var.name}"
    },
    var.tags,
    var.vpc_tags
  )
}

resource "aws_internet_gateway" "this" {
  count  = var.create_igw && length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(
    {
      Name = "${var.name}"
    },
    var.tags,
    var.igw_tags
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets) > 0 && (length(var.public_subnets) <= length(local.azs)) ? length(var.public_subnets) : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = length(regexall("^[a-z]{2}-", local.azs.names[count.index])) > 0 ? local.azs.names[count.index] : null
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      Name = "${var.name}-Public-${count.index + 1}"
    },
    var.tags,
    var.public_subnet_tags
  )
}

resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  route = [
    {
      cidr_block                               = "0.0.0.0/0"
      gateway_id                               = aws_internet_gateway.this[count.index].id
      carrier_gateway_id                       = null
      egress_only_gateway_id                   = null
      destination_prefix_list_id               = null
      nat_gateway_id                           = null
      instance_id                              = null
      ipv6_cidr_block                          = null
      local_gateway_id                         = null
      network_interface_id                     = null
      transit_gateway_id                       = null
      vpc_endpoint_id                          = null
      vpc_peering_connection_id                = null
      carrier_gegress_only_gateway_idateway_id = null
    }
  ]

  tags = merge(
    {
      Name = "${var.name}-Public-${count.index + 1}"
    },
    var.tags,
    var.public_route_table_tags,
  )
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets) > 0 ? 1 : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets) > 0 && (length(var.private_subnets) <= length(local.azs)) ? length(var.private_subnets) : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = length(regexall("^[a-z]{2}-", local.azs.names[count.index])) > 0 ? local.azs.names[count.index] : null
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name = "${var.name}-Private-${count.index + 1}"
    },
    var.tags,
    var.private_subnet_tags
  )
}

resource "aws_route_table" "private" {
  count  = var.nat_gateway_count > 0 && (length(var.private_subnets) > 0 && length(var.public_subnets) > 0) ? var.nat_gateway_count : 0
  vpc_id = aws_vpc.this[0].id

  route = [
    {
      cidr_block                               = "0.0.0.0/0"
      nat_gateway_id                           = aws_nat_gateway.this[count.index].id
      carrier_gateway_id                       = null
      egress_only_gateway_id                   = null
      destination_prefix_list_id               = null
      gateway_id                               = null
      instance_id                              = null
      ipv6_cidr_block                          = null
      local_gateway_id                         = null
      network_interface_id                     = null
      transit_gateway_id                       = null
      vpc_endpoint_id                          = null
      vpc_peering_connection_id                = null
      carrier_gegress_only_gateway_idateway_id = null
    }
  ]

  tags = merge(
    {
      Name = "${var.name}-Private-${count.index + 1}"
    },
    var.tags,
    var.private_route_table_tags,
  )
}

resource "aws_route_table_association" "private" {
  count          = var.nat_gateway_count > 0 && length(var.private_subnets) > 0 ? var.nat_gateway_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_subnet" "intra" {
  count = length(var.intra_subnets) > 0 ? length(var.intra_subnets) : 0

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.intra_subnets[count.index]
  availability_zone       = length(regexall("^[a-z]{2}-", local.azs.names[count.index])) > 0 ? local.azs.names[count.index] : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(local.azs.names, count.index))) == 0 ? element(local.azs.names, count.index) : null
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name = "${var.name}-Intra-${count.index + 1}"
    },
    var.tags,
    var.intra_subnet_tags,
  )
}

resource "aws_route_table" "intra" {
  count  = length(var.intra_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(
    {
      Name = "${var.name}-Intra-${count.index + 1}"
    },
    var.tags,
    var.intra_route_table_tags,
  )
}

resource "aws_route_table_association" "intra" {
  count          = length(var.intra_subnets) > 0 ? 1 : 0
  subnet_id      = aws_subnet.intra[count.index].id
  route_table_id = aws_route_table.intra[count.index].id
}

resource "aws_eip" "nat" {
  count = var.nat_gateway_count > 0 && length(var.public_subnets) > 0 ? var.nat_gateway_count : 0

  vpc = true

  tags = merge(
    {
      Name = "${var.name}-nat_eip-${count.index + 1}"
    },
    var.tags,
    var.nat_eip_tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = var.nat_gateway_count > 0 && length(var.public_subnets) > 0 ? var.nat_gateway_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name = "${var.name}-natgw-${count.index + 1}"
    },
    var.tags,
    var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

# ### -------------------------------------------------------------------------------------------- ###
# ### EC2 INSTANCES
# ### -------------------------------------------------------------------------------------------- ###

# resource "aws_key_pair" "aws_test_key" {
#   key_name   = var.key_name
#   public_key = var.priv_key.public_key_openssh
# }

# data "aws_ami" "amzn2_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm*"]
#   }

#   filter {
#     name   = "state"
#     values = ["available"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

# data "aws_ami" "latest_ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"]

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server*"]
#   }
# }

# data "template_file" "cloud_config" {
#   count    = length(var.hostnames)
#   template = file("${path.module}/templates/cloud-config.tpl")

#   vars = {
#     hostname = var.hostnames[count.index]
#     ssh_key  = data.local_file.ssh_key.content
#   }
# }

# data "local_file" "ssh_key" {
#   filename = pathexpand("${var.priv_ssh_key_path}/${aws_key_pair.aws_test_key.key_name}")

#   depends_on = [
#     aws_key_pair.aws_test_key
#   ]
# }

# resource "aws_network_interface" "hub" {
#   count             = 1
#   subnet_id         = aws_subnet.public[0].id
#   security_groups   = [aws_security_group.hub_public.id]
#   private_ips       = [cidrhost(aws_subnet.public[count.index].cidr_block, 10)]
#   source_dest_check = true

#   tags = {
#     Name = "Hub Public"
#   }
# }

# resource "aws_instance" "hub_public" {
#   count            = 1
#   ami              = data.aws_ami.amzn2_linux.id
#   instance_type    = "t3.medium"
#   key_name         = aws_key_pair.aws_test_key.key_name
#   user_data_base64 = base64encode(data.template_file.cloud_config[count.index].rendered)

#   network_interface {
#     network_interface_id = aws_network_interface.hub.*.id[0]
#     device_index         = 0
#   }

#   tags = {
#     Name = "Hub Bastion"
#   }

#   depends_on = [aws_key_pair.aws_test_key]
# }

# resource "aws_network_interface" "private" {
#   count             = 4
#   subnet_id         = aws_subnet.private[count.index].id
#   private_ips       = [cidrhost(aws_subnet.private[count.index].cidr_block, 10)]
#   source_dest_check = true

#   security_groups = [
#     [
#       aws_security_group.hub_private.id,
#       aws_security_group.spoke_1.id,
#       aws_security_group.spoke_2.id,
#       aws_security_group.spoke_3.id
#   ][count.index]]

#   tags = element([
#     {
#       Name = "Hub Private"
#     },
#     {
#       Name = "Spoke 1"
#     },
#     {
#       Name = "Spoke 2"
#     },
#     {
#       Name = "Spoke 3"
#     }
#   ], count.index)
# }

# ## Spoke VPC Instances

# resource "aws_instance" "private" {
#   count            = 4
#   ami              = data.aws_ami.amzn2_linux.id
#   instance_type    = "t3.medium"
#   key_name         = aws_key_pair.aws_test_key.key_name
#   user_data_base64 = base64encode(data.template_file.cloud_config[count.index + 1].rendered)

#   network_interface {
#     network_interface_id = aws_network_interface.private[count.index].id
#     device_index         = 0
#   }

#   tags = element([
#     {
#       Name = "Hub Private"
#     },
#     {
#       Name = "Spoke 1"
#     },
#     {
#       Name = "Spoke 2"
#     },
#     {
#       Name = "Spoke 3"
#     }
#   ], count.index)

#   depends_on = [aws_key_pair.aws_test_key]
# }

# ### -------------------------------------------------------------------------------------------- ###
# ### SECURITY GROUPS
# ### -------------------------------------------------------------------------------------------- ###

# resource "aws_security_group" "hub_public" {
#   description = "Hub instances Public SG"
#   vpc_id      = aws_vpc.vpcs.*.id[0]

#   tags = {
#     Name = "Hub Public"
#   }
# }


# resource "aws_security_group" "hub_private" {
#   description = "Hub instances Private SG"
#   vpc_id      = aws_vpc.vpcs.*.id[0]

#   tags = {
#     Name = "Hub Private"
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
#       description              = "Allow ALL from Hub Private subnet"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       source_security_group_id = aws_security_group.hub_private.id
#       cidr_blocks              = null
#       security_group_id        = aws_security_group.hub_public.id
#     }

#     public_rule_4 = {
#       description              = "Allow ALL from Hub Public to self"
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
#       description              = "Allow all from Spoke VPC 1"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[1].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_2 = {
#       description              = "Allow all from Spoke VPC 2"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[2].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_3 = {
#       description              = "Allow all from Spoke VPC 3"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[3].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_4 = {
#       description              = "Allow ALL from Hub Public subnet"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       source_security_group_id = aws_security_group.hub_public.id
#       cidr_blocks              = null
#       security_group_id        = aws_security_group.hub_private.id
#     }

#     private_rule_5 = {
#       description              = "Allow ALL from Hub Private (self)"
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
#       description              = "Allow ALL from Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[0].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_1.id
#     }

#     rule_3 = {
#       description              = "Allow ALL from Spoke 2"
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
#       description              = "Allow ALL from Hub"
#       type                     = "ingress"
#       from_port                = 0
#       to_port                  = 0
#       protocol                 = "-1"
#       cidr_blocks              = [aws_vpc.vpcs[0].cidr_block]
#       source_security_group_id = null
#       security_group_id        = aws_security_group.spoke_2.id
#     }

#     rule_3 = {
#       description              = "Allow ALL from Spoke 1"
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
#       description              = "Allow ALL from Hub"
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
#   description = "Spoke 1 Private"
#   vpc_id      = aws_vpc.vpcs.*.id[1]

#   tags = {
#     Name = "Spoke 1"
#   }
# }

# resource "aws_security_group" "spoke_2" {
#   description = "Spoke 2 Private"
#   vpc_id      = aws_vpc.vpcs.*.id[2]

#   tags = {
#     Name = "Spoke 2"
#   }
# }

# resource "aws_security_group" "spoke_3" {
#   description = "Spoke 3 Private"
#   vpc_id      = aws_vpc.vpcs.*.id[3]

#   tags = {
#     Name = "Spoke 3"
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
