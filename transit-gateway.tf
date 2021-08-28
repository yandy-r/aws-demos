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

resource "aws_ec2_transit_gateway_vpc_attachment" "attach" {
  count                                           = length(aws_subnet.private)
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw1.id
  vpc_id                                          = aws_vpc.vpcs[count.index].id
  subnet_ids                                      = [aws_subnet.private[count.index].id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = [
    {
      Name = "Central VPC"
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

resource "aws_ec2_transit_gateway_route_table" "central" {
  count              = 1
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = element([
    {
      Name = "Central Route Table"
    }
  ], count.index)
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  count              = 1
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = element([
    {
      Name = "Spokes"
    }
  ], count.index)
}

resource "aws_ec2_transit_gateway_route_table_association" "central" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.central[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "spokes" {
  count                          = 3
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "central" {
  count                          = 4
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.central[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "central_to_spokes" {
  count                          = 1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_1_to_2" {
  count                          = 2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
}

resource "aws_ec2_transit_gateway_route" "spoke_defaults" {
  count                          = 1
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
}

resource "aws_ec2_transit_gateway_route" "black_hole" {
  count                          = 3
  destination_cidr_block         = var.rfc1918[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
  blackhole                      = "true"
}
