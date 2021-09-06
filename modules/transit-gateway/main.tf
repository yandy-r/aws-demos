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
### TRANSIT GATEWAY
### -------------------------------------------------------------------------------------------- ###

resource "aws_ec2_transit_gateway" "this" {
  for_each                        = { for k, v in var.transit_gateway : k => v }
  dns_support                     = lookup(each.value, "dns_support", "enable")
  description                     = lookup(each.value, "description", null)
  amazon_side_asn                 = lookup(each.value, "amazon_side_asn", 64512)
  vpn_ecmp_support                = lookup(each.value, "vpn_ecmp_support", "enable")
  auto_accept_shared_attachments  = lookup(each.value, "auto_accept_shared_attachments", "disable")
  default_route_table_association = lookup(each.value, "default_route_table_association", "disable")
  default_route_table_propagation = lookup(each.value, "default_route_table_propagation", "disable")

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "${each.key + 1}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

locals {
  transit_gateway_id = one([for v in aws_ec2_transit_gateway.this : v.id])
  vpc_attachment_ids = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id }
  route_table_ids    = { for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each                                        = { for k, v in var.vpc_attachments : k => v }
  vpc_id                                          = each.value["vpc_id"]
  subnet_ids                                      = each.value["subnet_ids"]
  transit_gateway_id                              = lookup(each.value, "transit_gateway_id", local.transit_gateway_id)
  ipv6_support                                    = lookup(each.value, "ipv6_support", "disable")
  dns_support                                     = lookup(each.value, "dns_support", "enable")
  appliance_mode_support                          = lookup(each.value, "appliance_mode_support", "disable")
  transit_gateway_default_route_table_association = lookup(each.value, "transit_gateway_default_route_table_association", false)
  transit_gateway_default_route_table_propagation = lookup(each.value, "transit_gateway_default_route_table_propagation", false)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "attach-${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = { for k, v in var.route_tables : k => v }
  transit_gateway_id = lookup(each.value, "transit_gateway_id", local.transit_gateway_id)

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = { for k, v in var.route_table_associations : k => v }
  transit_gateway_attachment_id  = lookup(each.value, "transit_gateway_attachment_id", local.vpc_attachment_ids[each.key])
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), lookup(local.route_table_ids, each.value.route_table_name, ""))
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = { for k, v in var.route_table_propagations : k => v }
  transit_gateway_attachment_id  = lookup(each.value, "transit_gateway_attachment_id", local.vpc_attachment_ids[each.value.attach_name])
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), lookup(local.route_table_ids, each.value.route_table_name, ""))
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = { for k, v in var.transit_gateway_routes : k => v }
  blackhole                      = lookup(each.value, "blackhole", null)
  destination_cidr_block         = each.value.destination
  transit_gateway_attachment_id  = tobool(lookup(each.value, "blackhole", false)) == false ? local.vpc_attachment_ids[each.value.attach_name] : null
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), lookup(local.route_table_ids, each.value.route_table_name, ""))
}

resource "aws_route" "this" {
  for_each                  = { for k, v in var.vpc_routes : k => v }
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

# resource "aws_ec2_transit_gateway_peering_attachment" "east_west" {
#   peer_region             = local.west_region
#   transit_gateway_id      = local.east_tgw.id
#   peer_transit_gateway_id = local.west_tgw.id

#   tags = {
#     Name = "EAST->WEST"
#   }
# }

# resource "aws_ec2_transit_gateway_peering_attachment_accepter" "east_west" {
#   transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.east_west.id

#   tags = {
#     Name = "WEST->EAST"
#   }
# }
