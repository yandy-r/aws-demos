data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_vpc" "vpcs" {
  count                = 4
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  cidr_block = element(["10.240.0.0/16", "10.241.0.0/16", "10.242.0.0/16", "10.243.0.0/16"], count.index)

  tags = element([
    {
      Name = "Core VPC"
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
  vpc_id = aws_vpc.vpcs.*.id[0]

  tags = {
    Name = "Core InetGW"
  }
}

resource "aws_subnet" "public" {
  count                   = 1
  vpc_id                  = element(aws_vpc.vpcs.*.id, count.index)
  cidr_block              = cidrsubnet(aws_vpc.vpcs.*.cidr_block[0], 8, 0)
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = "true"

  tags = element([
    {
      Name = "Core VPC Public Subnet"
    }
  ], count.index)
}

resource "aws_subnet" "private" {
  count                   = 4
  vpc_id                  = element(aws_vpc.vpcs.*.id, count.index)
  cidr_block              = cidrsubnet(element(aws_vpc.vpcs.*.cidr_block, count.index), 8, 128)
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index + 1)
  map_public_ip_on_launch = "false"

  tags = element([
    {
      Name = "Core VPC Private Subnet"
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
      Name = "Core Public RT"
    }
  ], count.index)
}

resource "aws_route_table" "private" {
  count  = 4
  vpc_id = element(aws_vpc.vpcs.*.id, count.index)

  tags = element([
    {
      Name = "Core Private RT"
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
  count          = 1
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = 4
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route" "core_default" {
  route_table_id         = aws_route_table.public.*.id[0]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

resource "aws_route" "core_default2" {
  route_table_id         = aws_route_table.private.*.id[0]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

resource "aws_route" "tgw1_core_routes" {
  count                  = length(aws_route_table.public)
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

resource "aws_route" "tgw1_spoke_routes" {
  count                  = length(aws_route_table.private)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "10.0.0.0/8"
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
