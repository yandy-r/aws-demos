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
  for_each                                        = { for k, v in var.vpc_attachments : k => v if length(var.vpc_attachments) > 0 }
  transit_gateway_id                              = lookup(each.value, "tgw_id", var.create_tgw ? aws_ec2_transit_gateway.this[0].id : null)
  vpc_id                                          = each.value["vpc_id"]
  subnet_ids                                      = each.value["subnet_ids"]
  transit_gateway_default_route_table_association = lookup(each.value, "default_asssociation", false)
  transit_gateway_default_route_table_propagation = lookup(each.value, "default_propagation", false)

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = { for k, v in var.route_tables : k => v if length(var.route_tables) > 0 }
  transit_gateway_id = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = { for k, v in var.route_table_associations : k => v if length(var.route_table_associations) > 0 }
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.key].id
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id)
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = { for k, v in var.route_table_propagations : k => v if length(var.route_table_propagations) > 0 }
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[each.value.attach_name].id
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id)
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = { for k, v in var.tgw_routes : k => v if length(var.tgw_routes) > 0 }
  blackhole                      = lookup(each.value, "blackhole", null)
  destination_cidr_block         = each.value.destination
  transit_gateway_attachment_id  = tobool(lookup(each.value, "blackhole", false)) == false ? aws_ec2_transit_gateway_vpc_attachment.this[each.value.attach_id].id : null
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id)
}

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
