module "transit_gateway" {
  ## Transit Gateway
  source = "git::ssh://git@github.com/IPyandy/terraform-aws-modules.git//transit-gateway?ref=terraform-0.12"

  create_transit_gateway          = true
  transit_gateway_description     = "Transit Gateway Demo"
  amazon_side_asn                 = 65100
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  transit_gateway_tags = {
    Name = "Transit-Gateway-01"
  }

  ## VPC Attachments
  vpc_ids = concat(local.core_vpc_ids, local.spoke_vpc_ids)
  subnet_ids = [
    local.core_private_subnet_ids,
    local.spoke_1_subnet_ids,
    local.spoke_2_subnet_ids,
  ]
  ipv6_support = "disable"

  ### Note that since we're using custom transit gateway route tables the
  ### defautl route table attachment and default route table propagation
  ### needs to be disabled, otherwise conflics when the custom attachments
  ### are created will prevent ths from completing deployment.
  associate_default_route_table       = false
  vpc_default_route_table_propagation = false
  vpc_attachment_tags = [
    {
      Name = "Core-VPC-Attachment"
    },
    {
      Name = "Spoke-1-VPC-Attachment"
    },
    {
      Name = "Spoke-2-VPC-Attachment"
    },
  ]

  ### spoke route tables

  ### create_custom_route_tables is set to true to prevent the transit gateway
  ### from setting default atachments as well
  create_custom_route_tables = true
  route_table_count          = length(concat(local.core_vpc_ids, local.spoke_vpc_ids))
  route_table_tags = [
    {
      Name = "Core-VPC-Route-Table"
    },
    {
      Name = "Spoke-1-VPC-Route-Table"
    },
    {
      Name = "Spoke-2-VPC-Route-Table"
    },
  ]
}

# propagate from source VPC (attachments) to core route table
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_core" {
  count                          = 2
  transit_gateway_attachment_id  = module.transit_gateway.vpc_attachment_ids[count.index + 1]
  transit_gateway_route_table_id = module.transit_gateway.route_table_ids[0]
}

# create static default route on transit gateway from spoke routing tables to core routing table
# attachment[0] is core vpc attachment
resource "aws_ec2_transit_gateway_route" "default_routes" {
  count                          = 3
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.transit_gateway.vpc_attachment_ids[0]
  transit_gateway_route_table_id = module.transit_gateway.route_table_ids[count.index]
}

resource "aws_route" "core_route_spokes" {
  count                  = length(local.core_route_table_ids)
  route_table_id         = local.core_route_table_ids[count.index]
  destination_cidr_block = "10.244.0.0/14"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
}

resource "aws_route" "spoke_default_routes" {
  count                  = length(local.spoke_priv_route_table_ids)
  route_table_id         = local.spoke_priv_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
}
