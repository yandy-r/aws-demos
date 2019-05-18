module "transit_gateway" {
  # Transit Gateway
  source = "../modules/aws/transit-gateway"
  # source                          = "git::ssh://git@github.com/IPyandy/terraform-aws-modules.git//transit-gateway?ref=terraform-0.12"

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

  # VPC Attachments
  vpc_ids                             = concat(local.core_vpc_ids, local.stub_vpc_ids)
  subnet_ids                          = [local.core_private_subnet_ids, local.stub1_subnet_ids, local.stub2_subnet_ids]
  ipv6_support                        = "disable"
  associate_default_route_table       = false
  vpc_default_route_table_propagation = false
  vpc_attachment_tags = [
    {
      Name = "Core VPC Attachment"
    },
    {
      Name = "Stub-1 VPC Attachment"
    },
    {
      Name = "Stub-2 VPC Attachment"
    }
  ]

  # stub route tables
  create_custom_route_tables = true
  route_table_count          = length(concat(local.core_vpc_ids, local.stub_vpc_ids))
  route_table_tags = [
    {
      Name = "Core VPC Route Table"
    },
    {
      Name = "Stub-1 VPC Route Table"
    },
    {
      Name = "Stub-2 VPC Route Table"
    }
  ]
}

# propagate from source VPC (attachments) to core route table
resource "aws_ec2_transit_gateway_route_table_propagation" "stubs_to_core" {
  count                          = 2
  transit_gateway_attachment_id  = module.transit_gateway.vpc_attachment_ids[count.index + 1]
  transit_gateway_route_table_id = module.transit_gateway.route_table_ids[0]
}

# create static default route on transit gateway from stub routing tables to core routing table
# attachment[0] is core vpc attachment
resource "aws_ec2_transit_gateway_route" "default_routes" {
  count                          = 3
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.transit_gateway.vpc_attachment_ids[0]
  transit_gateway_route_table_id = module.transit_gateway.route_table_ids[count.index]
}

resource "aws_route" "core_route_stubs" {
  count                  = length(local.core_route_table_ids)
  route_table_id         = local.core_route_table_ids[count.index]
  destination_cidr_block = "10.244.0.0/14"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
}

resource "aws_route" "stub_default_routes" {
  count                  = length(local.stub_priv_route_table_ids)
  route_table_id         = local.stub_priv_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
}
