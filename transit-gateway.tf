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

resource "aws_ec2_transit_gateway_vpc_attachment" "core_vpc_attachment" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw1.id
  vpc_id                                          = module.core_vpc.vpc_id
  subnet_ids                                      = module.core_vpc.public_subnets.*.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "Core VPC Attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "core_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = {
    Name = "Core Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "core_route_table_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.core_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "core" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.core_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1_to_core" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_2_to_core" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_3_to_core" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_3_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core_route_table.id
}

### SPOKE 1 AND 2

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_1_vpc_attachment" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw1.id
  vpc_id                                          = module.spoke_1_vpc.vpc_id
  subnet_ids                                      = module.spoke_1_vpc.private_subnets.*.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "Spoke 1 VPC Attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_2_vpc_attachment" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw1.id
  vpc_id                                          = module.spoke_2_vpc.vpc_id
  subnet_ids                                      = module.spoke_2_vpc.private_subnets.*.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "Spoke 2 VPC Attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke_1_2_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = {
    Name = "Spoke 1 & 2 Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_1_route_table_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_1_2_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_2_route_table_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_1_2_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_1_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_1_2_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_2_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_1_2_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "core_to_spoke_1_2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.core_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_1_2_route_table.id
}

### SPOKE 3

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_3_vpc_attachment" {
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw1.id
  vpc_id                                          = module.spoke_3_vpc.vpc_id
  subnet_ids                                      = module.spoke_3_vpc.private_subnets.*.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "Spoke 3 VPC Attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke_3_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id

  tags = {
    Name = "Spoke 3 Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_3_route_table_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_3_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_3_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_3" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_3_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_3_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "core_to_spoke_3" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.core_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_3_route_table.id
}

### ALL DEFAULT ROUTES

resource "aws_ec2_transit_gateway_route" "routes" {
  count                         = 3
  destination_cidr_block        = "0.0.0.0/0"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.core_vpc_attachment.id
  transit_gateway_route_table_id = element([aws_ec2_transit_gateway_route_table.core_route_table.id,
    aws_ec2_transit_gateway_route_table.spoke_1_2_route_table.id,
  aws_ec2_transit_gateway_route_table.spoke_3_route_table.id], count.index)
}
