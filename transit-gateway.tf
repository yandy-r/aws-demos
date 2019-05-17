resource "aws_ec2_transit_gateway" "this" {
  description                    = "Awesome Transit Gateway"
  amazon_side_asn                = 65100
  auto_accept_shared_attachments = "enable"
  dns_support                    = "enable"
  vpn_ecmp_support               = "enable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "stub_attachment" {
  count              = length(local.stub_vpc_ids)
  subnet_ids         = local.stub_subnet_ids[count.index]
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = local.stub_vpc_ids[count.index]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "core_attachment" {
  count              = length(local.core_vpc_ids)
  subnet_ids         = local.core_private_subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = local.core_vpc_ids[count.index]
}

resource "aws_ec2_transit_gateway_route" "default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.core_attachment[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.this.association_default_route_table_id
}

resource "aws_route" "core_routes" {
  count                  = length(local.core_route_table_ids)
  route_table_id         = local.core_route_table_ids[count.index]
  destination_cidr_block = "10.244.0.0/14"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "stub_routes" {
  count                  = length(local.stub_priv_route_table_ids)
  route_table_id         = local.stub_priv_route_table_ids[count.index]
  destination_cidr_block = "10.244.0.0/14"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "stub_default_routes" {
  count                  = length(local.stub_priv_route_table_ids)
  route_table_id         = local.stub_priv_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

output "transit_gateway" {
  value = aws_ec2_transit_gateway.this
}

