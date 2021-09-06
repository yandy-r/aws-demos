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
  azs                        = data.aws_availability_zones.azs
  vpc_id                     = { for k, v in aws_vpc.this : k => v.id }
  cidr_block                 = { for k, v in aws_vpc.this : k => v.cidr_block }
  internet_gateway_id        = [for v in aws_internet_gateway.this : v.id]
  nat_gateway_id             = [for v in aws_nat_gateway.this : v.id]
  public_subnet_ids          = [for v in aws_subnet.public : v.id]
  public_subnet_cidr_blocks  = [for v in aws_subnet.public : v.cidr_block]
  private_subnet_ids         = [for v in aws_subnet.private : v.id]
  private_subnet_cidr_blocks = [for v in aws_subnet.private : v.cidr_block]
  intra_subnet_ids           = [for v in aws_subnet.intra : v.id]
  intra_subnet_cidr_blocks   = [for v in aws_subnet.intra : v.cidr_block]
  public_route_table_id      = [for v in aws_route_table.public : v.id]
  private_route_table_id     = [for v in aws_route_table.private : v.id]
  intra_route_table_id       = [for v in aws_route_table.intra : v.id]
  route_table_ids            = flatten([local.public_route_table_id[*], local.private_route_table_id[*], local.intra_route_table_id[*]])
  security_group_ids         = { for k, v in aws_security_group.this : k => v.id }
}

resource "aws_internet_gateway" "this" {
  for_each = { for k, v in var.internet_gateway : k => v }
  vpc_id   = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))

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
  vpc_id                  = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))
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
  vpc_id   = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))

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
  route_table_id = lookup(each.value, "route_table_id", aws_route_table.public[0].id)
}

resource "aws_subnet" "private" {
  for_each                = { for k, v in var.private_subnets : k => v }
  vpc_id                  = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))
  cidr_block              = each.value["cidr_block"]
  availability_zone       = lookup(each.value, "availability_zone", true) != true ? each.value["availability_zone"] : random_shuffle.subnet_azs.result[random_integer.this.result]
  map_public_ip_on_launch = lookup(each.value, "map_public_ip_on_launch", true)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "private-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route_table" "private" {
  for_each = { for k, v in var.private_route_table : k => v }
  vpc_id   = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))

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
  route_table_id = lookup(each.value, "route_table_id", aws_route_table.private[0].id)
}

resource "aws_subnet" "intra" {
  for_each                = { for k, v in var.intra_subnets : k => v }
  vpc_id                  = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))
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
  vpc_id   = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))

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
  route_table_id = lookup(each.value, "route_table_id", aws_route_table.intra[0].id)
}

resource "aws_route" "internet_gateway_default" {
  for_each               = { for k, v in aws_internet_gateway.this : k => v }
  route_table_id         = lookup(each.value, "route_table_id", aws_route_table.public[each.key].id)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = lookup(each.value, "internet_gateway_id", aws_internet_gateway.this[each.key].id)
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
  vpc_id            = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))
  vpc_endpoint_type = lookup(each.value, "endpoint_type", "Gateway")
  service_name      = lookup(each.value, "service_name", "com.amazonaws.${data.aws_region.current.name}.${each.value["service_type"]}")
  policy            = lookup(each.value, "policy", null)
  route_table_ids   = lookup(each.value, "route_table_ids", local.route_table_ids)

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
  for_each    = { for k, v in var.security_groups : k => v }
  description = lookup(each.value, "description", null)
  vpc_id      = lookup(each.value, "vpc_id", lookup(each.value, "vpc_name", ""))

  dynamic "egress" {
    for_each = lookup(each.value, "egress", {})
    content {
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      protocol         = egress.value["protocol"]
      self             = lookup(egress.value, "self", null)
      description      = lookup(egress.value, "description", null)
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      security_groups  = lookup(egress.value, "security_groups", null)
    }
  }

  dynamic "ingress" {
    for_each = lookup(each.value, "ingress", {})
    content {
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      protocol         = ingress.value["protocol"]
      self             = lookup(ingress.value, "self", null)
      description      = lookup(ingress.value, "description", null)
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "sg-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_security_group_rule" "security_group_rules" {
  for_each                 = { for k, v in var.security_group_rules : k => v }
  description              = lookup(each.value, "description", null)
  type                     = lookup(each.value, "type", null)
  from_port                = lookup(each.value, "from_port", null)
  to_port                  = lookup(each.value, "to_port", null)
  protocol                 = lookup(each.value, "protocol", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  security_group_id        = lookup(each.value, "security_group_id", null)
}

# ### -------------------------------------------------------------------------------------------- ###
# ### FLOW LOGS
# ### -------------------------------------------------------------------------------------------- ###

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
