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
  vpc_id = aws_vpc.this.id

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
  vpc_id                  = aws_vpc.this.id
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
  vpc_id = aws_vpc.this.id

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
  vpc_id                  = aws_vpc.this.id
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
  vpc_id = aws_vpc.this.id

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

  vpc_id                  = aws_vpc.this.id
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
  vpc_id = aws_vpc.this.id

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

# resource "aws_route_table" "public" {
#   count  = 1
#   vpc_id = element(aws_vpc.vpcs.*.id, count.index)

#   tags = element([
#     {
#       Name = "Hub Public RT"
#     }
#   ], count.index)
# }

# resource "aws_route_table" "private" {
#   count  = 4
#   vpc_id = element(aws_vpc.vpcs.*.id, count.index)

#   tags = element([
#     {
#       Name = "Hub Private RT"
#     },
#     {
#       Name = "Spoke 1 Private RT"
#     },
#     {
#       Name = "Spoke 2 Private RT"
#     },
#     {
#       Name = "Spoke 3 Private RT"
#     },
#   ], count.index)
# }

# resource "aws_route_table_association" "public" {
#   count          = length(aws_route_table.public)
#   subnet_id      = aws_subnet.public[count.index].id
#   route_table_id = aws_route_table.public[count.index].id
# }

# resource "aws_route_table_association" "private" {
#   count          = length(aws_route_table.private)
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }

# resource "aws_route" "hub_inet_gw_default" {
#   route_table_id         = aws_route_table.public[0].id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.inet_gw.id
# }

# resource "aws_route" "hub_nat_gw_default" {
#   route_table_id         = aws_route_table.private[0].id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat_gw.id
# }

# resource "aws_route" "hub_to_spokes_private" {
#   count                  = 3
#   route_table_id         = aws_route_table.private[0].id
#   destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
#   transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
# }

# resource "aws_route" "hub_to_spokes_public" {
#   count                  = 3
#   route_table_id         = aws_route_table.public[0].id
#   destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
#   transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
# }

# resource "aws_route" "tgw_spoke_defaults" {
#   count                  = 3
#   route_table_id         = aws_route_table.private[count.index + 1].id
#   destination_cidr_block = "0.0.0.0/0"
#   transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
# }

# ### FLOW LOGS

# resource "aws_iam_role" "flow_logs" {
#   count              = var.create_flow_logs ? 1 : 0
#   name               = "${data.aws_region.current.name}-flow_logs"
#   assume_role_policy = file("${path.module}/templates/flow_logs_role.json")

#   tags = {
#     Name = "Flow Logs"
#   }
# }

# resource "aws_iam_role_policy" "flow_logs" {
#   count  = var.create_flow_logs ? 1 : 0
#   name   = "${data.aws_region.current.name}-flow_logs"
#   role   = aws_iam_role.flow_logs[0].id
#   policy = file("${path.module}/templates/flow_logs_role_policy.json")
# }

# resource "aws_cloudwatch_log_group" "flow_logs" {
#   count = var.create_flow_logs ? 1 : 0
#   name  = "${data.aws_region.current.name}-flow_logs"

#   tags = {
#     Name = "Flow logs"
#   }
# }

# resource "aws_flow_log" "flow_logs" {
#   count           = var.create_flow_logs ? length(aws_vpc.vpcs) : 0
#   iam_role_arn    = aws_iam_role.flow_logs[0].arn
#   log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.vpcs[count.index].id
# }

# data "template_file" "s3_endpoint_policy" {
#   template = file("${path.module}/templates/s3_endpoint_policy.json")

#   vars = {
#     bucket_arn = aws_s3_bucket.lab_data.arn
#   }
# }

# data "aws_region" "current" {}
# resource "aws_vpc_endpoint" "s3" {
#   count             = var.create_vpc_endpoint ? 1 : 0
#   vpc_id            = aws_vpc.vpcs[0].id
#   vpc_endpoint_type = "Gateway"
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
#   policy            = data.template_file.s3_endpoint_policy.rendered

#   tags = {
#     Name = "S3 Endpoint"
#   }
# }

# locals {
#   hub_rts = [
#     aws_route_table.public[0], aws_route_table.private[0]
#   ]
# }
# resource "aws_vpc_endpoint_route_table_association" "s3" {
#   for_each        = { for k, v in local.hub_rts : k => v.id }
#   route_table_id  = each.value
#   vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
# }

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
# ### TRANSIT GATEWAY
# ### -------------------------------------------------------------------------------------------- ###

# resource "aws_ec2_transit_gateway" "tgw" {
#   description                     = "Transit Gateway Demo"
#   amazon_side_asn                 = "64512"   # default
#   auto_accept_shared_attachments  = "disable" # default
#   default_route_table_association = "disable"
#   default_route_table_propagation = "disable"
#   dns_support                     = "enable" # default
#   vpn_ecmp_support                = "enable" # default

#   tags = {
#     Name = "TGW-${var.region}"
#   }
# }

# resource "aws_ec2_transit_gateway_vpc_attachment" "attach" {
#   count                                           = length(aws_subnet.private)
#   transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
#   vpc_id                                          = aws_vpc.vpcs[count.index].id
#   subnet_ids                                      = [aws_subnet.private[count.index].id]
#   transit_gateway_default_route_table_association = false
#   transit_gateway_default_route_table_propagation = false

#   tags = [
#     {
#       Name = "Hub VPC"
#     },
#     {
#       Name = "Spoke 1 VPC"
#     },
#     {
#       Name = "Spoke 2 VPC"
#     },
#     {
#       Name = "Spoke 3 VPC"
#   }][count.index]
# }

# resource "aws_ec2_transit_gateway_route_table" "hub" {
#   count              = 1
#   transit_gateway_id = aws_ec2_transit_gateway.tgw.id

#   tags = element([
#     {
#       Name = "Hub Route Table"
#     }
#   ], count.index)
# }

# resource "aws_ec2_transit_gateway_route_table" "spokes" {
#   count              = 1
#   transit_gateway_id = aws_ec2_transit_gateway.tgw.id

#   tags = element([
#     {
#       Name = "Spokes"
#     }
#   ], count.index)
# }

# resource "aws_ec2_transit_gateway_route_table_association" "hub" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub[0].id
# }

# resource "aws_ec2_transit_gateway_route_table_association" "spokes" {
#   count                          = 3
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "hub" {
#   count                          = 4
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub[0].id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "hub_to_spokes" {
#   count                          = 1
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_1_to_2" {
#   count                          = 2
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
# }

# resource "aws_ec2_transit_gateway_route" "spoke_defaults" {
#   count                          = 1
#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
# }

# resource "aws_ec2_transit_gateway_route" "black_hole" {
#   count                          = 3
#   destination_cidr_block         = var.rfc1918[count.index]
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
#   blackhole                      = "true"
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
