terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = var.tgw_attachments[0]
  transit_gateway_route_table_id = var.tgw_route_tables[0]
}

resource "aws_ec2_transit_gateway_route_table_association" "spokes" {
  count                          = length(var.tgw_attachments) - 1
  transit_gateway_attachment_id  = var.tgw_attachments[count.index + 1]
  transit_gateway_route_table_id = var.tgw_route_tables[1]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub_to_spokes" {
  transit_gateway_attachment_id  = var.tgw_attachments[0]
  transit_gateway_route_table_id = var.tgw_route_tables[1]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_hub" {
  count                          = length(var.tgw_attachments) - 1
  transit_gateway_attachment_id  = var.tgw_attachments[count.index + 1]
  transit_gateway_route_table_id = var.tgw_route_tables[0]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_1_to_spoke_2" {
  count                          = length(var.tgw_attachments) - 2
  transit_gateway_attachment_id  = var.tgw_attachments[count.index + 1]
  transit_gateway_route_table_id = var.tgw_route_tables[1]
}
