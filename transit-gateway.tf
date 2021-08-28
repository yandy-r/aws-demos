resource "aws_ec2_transit_gateway" "tgw1" {
  description                     = "Transit Gateway Demo"
  amazon_side_asn                 = "64512"   # default
  auto_accept_shared_attachments  = "disable" # default
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable" # default
  vpn_ecmp_support                = "enable" # default

  tags = {
    Name = "TGW1"
  }
}

### CORE VPC
locals {
  subnet_ids = [
    [aws_subnet.public[0].id, aws_subnet.private[0].id],
    [aws_subnet.private[1].id],
    [aws_subnet.private[2].id],
    [aws_subnet.private[3].id]
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attach" {
  count                                           = length(aws_vpc.vpcs)
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw1.id
  vpc_id                                          = aws_vpc.vpcs.*.id[count.index]
  subnet_ids                                      = local.subnet_ids[count.index]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = [
    {
      Name = "Core VPC"
    },
    {
      Name = "Spoke 1 VPC"
    },
    {
      Name = "Spoke 2 VPC"
    },
    {
      Name = "Spoke 3 VPC"
  }][count.index]
}

resource "aws_ec2_transit_gateway_route_table" "core" {
  count              = 1
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = element([
    {
      Name = "Core Route Table"
    }
  ], count.index)
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  count              = 2
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = element([
    {
      Name = "Spoke 1 & 2 Route Table"
    },
    {
      Name = "Spoke 3 Route Table"
    }
  ], count.index)
}

resource "aws_ec2_transit_gateway_route_table_association" "core" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach.*.id[1]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.*.id[0]
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach.*.id[2]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.*.id[0]
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_3" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach.*.id[3]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.*.id[1]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "core" {
  count                          = 4
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.*.id[0]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "core_to_spokes" {
  count                          = 2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach.*.id[0]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_1_2" {
  count                          = 2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_3" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[3].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[1].id
}

resource "aws_ec2_transit_gateway_route" "core_default" {
  count                          = 1
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core[count.index].id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
}

resource "aws_ec2_transit_gateway_route" "spoke_defaults" {
  count                          = 2
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
}
