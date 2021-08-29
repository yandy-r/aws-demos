data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  azs = data.aws_availability_zones.azs
}

resource "aws_vpc" "vpcs" {
  count                = 4
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  cidr_block = element(["10.240.0.0/16", "10.241.0.0/16", "10.242.0.0/16", "10.243.0.0/16"], count.index)

  tags = element([
    {
      Name = "Central VPC"
    },
    {
      Name = "Spoke VPC 1"
    },
    {
      Name = "Spoke VPC 2"
    },
    {
      Name = "Spoke VPC 3"
    },
  ], count.index)
}

resource "aws_internet_gateway" "inet_gw" {
  vpc_id = aws_vpc.vpcs[0].id

  tags = {
    Name = "Central InetGW"
  }
}

resource "aws_eip" "nat_gw" {
  vpc = true

  tags = {
    Name = "Central NatGw"
  }

  depends_on = [aws_internet_gateway.inet_gw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.inet_gw]
}

resource "aws_subnet" "public" {
  count                   = 1
  vpc_id                  = element(aws_vpc.vpcs.*.id, count.index)
  cidr_block              = cidrsubnet(aws_vpc.vpcs[0].cidr_block, 8, 0)
  availability_zone       = local.azs.names[0]
  map_public_ip_on_launch = "true"

  tags = element([
    {
      Name = "Central VPC Public Subnet"
    }
  ], count.index)
}

resource "aws_subnet" "private" {
  count                   = 4
  vpc_id                  = aws_vpc.vpcs[count.index].id
  cidr_block              = cidrsubnet(aws_vpc.vpcs[count.index].cidr_block, 8, 128)
  availability_zone       = local.azs.names[count.index]
  map_public_ip_on_launch = "false"

  tags = element([
    {
      Name = "Central VPC Private Subnet"
    },
    {
      Name = "Spoke VPC 1 Private Subnet"
    },
    {
      Name = "Spoke VPC 2 Private Subnet"
    },
    {
      Name = "Spoke VPC 3 Private Subnet"
    },
  ], count.index)
}

resource "aws_route_table" "public" {
  count  = 1
  vpc_id = element(aws_vpc.vpcs.*.id, count.index)

  tags = element([
    {
      Name = "Central Public RT"
    }
  ], count.index)
}

resource "aws_route_table" "private" {
  count  = 4
  vpc_id = element(aws_vpc.vpcs.*.id, count.index)

  tags = element([
    {
      Name = "Central Private RT"
    },
    {
      Name = "Spoke 1 Private RT"
    },
    {
      Name = "Spoke 2 Private RT"
    },
    {
      Name = "Spoke 3 Private RT"
    },
  ], count.index)
}

resource "aws_route_table_association" "public" {
  count          = length(aws_route_table.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_route_table.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "central_inet_gw_default" {
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

resource "aws_route" "central_nat_gw_default" {
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route" "central_to_spokes_private" {
  count                  = 3
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

resource "aws_route" "central_to_spokes_public" {
  count                  = 3
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

resource "aws_route" "tgw1_spoke_defaults" {
  count                  = 3
  route_table_id         = aws_route_table.private[count.index + 1].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

### FLOW LOGS

resource "aws_iam_role" "flow_logs" {
  count              = var.create_flow_logs ? 1 : 0
  name               = "flow_logs"
  assume_role_policy = file("iam/flow_logs_role.json")

  tags = {
    Name = "Flow Logs"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count  = var.create_flow_logs ? 1 : 0
  name   = "flow_logs"
  role   = aws_iam_role.flow_logs[0].id
  policy = file("iam/flow_logs_role_policy.json")
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.create_flow_logs ? 1 : 0
  name  = "flow_logs"

  tags = {
    Name = "Flow logs"
  }
}

resource "aws_flow_log" "flow_logs" {
  count           = var.create_flow_logs ? length(aws_vpc.vpcs) : 0
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpcs[count.index].id
}

# resource "aws_vpc_endpoint" "s3" {
#   count =
#   vpc_id = aws_vpc.vpcs[0].id

# }
