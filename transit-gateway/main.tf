### -------------------------------------------------------------------------------------------- ###
### PROVIDERS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

### -------------------------------------------------------------------------------------------- ###
### TRANSIT GATEWAY
### -------------------------------------------------------------------------------------------- ###

resource "aws_ec2_transit_gateway" "this" {
  count                           = var.create_tgw ? 1 : 0
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support

  tags = merge(
    {
      Name = "${var.name}-tgw-${count.index + 1}"
    },
    var.tags,
    var.tgw_tags,
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count                                           = (var.create_vpc_attach && length(var.vpc_ids) > 0 && length(var.subnet_ids) > 0) && !var.create_custom_attach ? length(var.vpc_ids) : 0
  transit_gateway_id                              = aws_ec2_transit_gateway.this[0].id
  vpc_id                                          = var.vpc_ids[count.index]
  subnet_ids                                      = var.subnet_ids[count.index]
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation

  tags = merge(
    {
      Name = "${var.name}-${count.index}"
    },
    var.tags,
    var.attach_tags[count.index]
  )
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  count              = var.create_route_tables && var.num_route_tables > 0 ? var.num_route_tables : 0
  transit_gateway_id = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    {
      Name = "${var.name}-${count.index}"
    },
    var.tags,
    var.route_table_tags[count.index]
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = {
    for k, v in var.route_table_associatons : k => v
    if length(var.route_table_associatons) > 0
  }

  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = each.value.route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = var.route_table_propagations
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = each.value.route_table_id
}

# resource "aws_ec2_transit_gateway_route_table_propagation" "hub_to_spokes" {
#   count                          = 1
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_1_to_2" {
#   count                          = 2
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
# }

# resource "aws_ec2_transit_gateway_route" "spoke_defaults" {
#   count                          = 1
#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
# }

# resource "aws_ec2_transit_gateway_route" "black_hole" {
#   count                          = 3
#   destination_cidr_block         = var.rfc1918[count.index]
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
#   blackhole                      = "true"
# }

# resource "aws_route" "hub_to_spokes_private" {
#   count                  = 3
#   route_table_id         = aws_route_table.private[0].id
#   destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
#   transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
# }

# resource "aws_route" "hub_to_spokes_public" {
#   count                  = 3
#   route_table_id         = aws_route_table.public[0].id
#   destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
#   transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
# }

# resource "aws_route" "tgw_spoke_defaults" {
#   count                  = 3
#   route_table_id         = aws_route_table.private[count.index + 1].id
#   destination_cidr_block = "0.0.0.0/0"
#   transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
# }

# ### FLOW LOGS

# resource "aws_iam_role" "flow_logs" {
#   count              = var.create_flow_logs ? 1 : 0
#   name               = "${data.aws_region.current.name}-flow_logs"
#   assume_role_policy = file("${path.module}/templates/flow_logs_role.json")

#   tags = {
#     Name = "Flow Logs"
#   }
# }

# resource "aws_iam_role_policy" "flow_logs" {
#   count  = var.create_flow_logs ? 1 : 0
#   name   = "${data.aws_region.current.name}-flow_logs"
#   role   = aws_iam_role.flow_logs[0].id
#   policy = file("${path.module}/templates/flow_logs_role_policy.json")
# }

# resource "aws_cloudwatch_log_group" "flow_logs" {
#   count = var.create_flow_logs ? 1 : 0
#   name  = "${data.aws_region.current.name}-flow_logs"

#   tags = {
#     Name = "Flow logs"
#   }
# }

# resource "aws_flow_log" "flow_logs" {
#   count           = var.create_flow_logs ? length(aws_vpc.vpcs) : 0
#   iam_role_arn    = aws_iam_role.flow_logs[0].arn
#   log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.vpcs[count.index].id
# }

# data "template_file" "s3_endpoint_policy" {
#   template = file("${path.module}/templates/s3_endpoint_policy.json")

#   vars = {
#     bucket_arn = aws_s3_bucket.lab_data.arn
#   }
# }

# data "aws_region" "current" {}
# resource "aws_vpc_endpoint" "s3" {
#   count             = var.create_vpc_endpoint ? 1 : 0
#   vpc_id            = aws_vpc.vpcs[0].id
#   vpc_endpoint_type = "Gateway"
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
#   policy            = data.template_file.s3_endpoint_policy.rendered

#   tags = {
#     Name = "S3 Endpoint"
#   }
# }

# locals {
#   hub_rts = [
#     aws_route_table.public[0], aws_route_table.private[0]
#   ]
# }
# resource "aws_vpc_endpoint_route_table_association" "s3" {
#   for_each        = { for k, v in local.hub_rts : k => v.id }
#   route_table_id  = each.value
#   vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
# }
