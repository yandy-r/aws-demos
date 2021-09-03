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
  count                           = length(var.transit_gateway) > 0 ? 1 : 0
  dns_support                     = lookup(var.transit_gateway, "dns_support", "enable")
  description                     = lookup(var.transit_gateway, "description", null)
  amazon_side_asn                 = lookup(var.transit_gateway, "amazon_side_asn", 64512)
  vpn_ecmp_support                = lookup(var.transit_gateway, "vpn_ecmp_support", "enable")
  auto_accept_shared_attachments  = lookup(var.transit_gateway, "auto_accept_shared_attachments", "disable")
  default_route_table_association = lookup(var.transit_gateway, "default_route_table_association", "disable")
  default_route_table_propagation = lookup(var.transit_gateway, "default_route_table_propagation", "disable")

  tags = merge(
    {
      Name = "${var.name}"
    },
    var.tags,
    lookup(var.transit_gateway, "tags", null)
  )
}

locals {
  transit_gateway_id = one(aws_ec2_transit_gateway.this[*].id)
  vpc_attachment_ids = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id }
  route_table_ids    = { for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each                                        = var.vpc_attachments
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
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = var.route_tables
  transit_gateway_id = lookup(each.value, "transit_gateway_id", local.transit_gateway_id)

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = var.route_table_associations
  transit_gateway_attachment_id  = lookup(each.value, "transit_gateway_attachment_id", local.vpc_attachment_ids[each.key])
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), local.route_table_ids[each.value.route_table_name])
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = var.route_table_propagations
  transit_gateway_attachment_id  = lookup(each.value, "transit_gateway_attachment_id", local.vpc_attachment_ids[each.value.attach_name])
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), local.route_table_ids[each.value.route_table_name])
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = var.transit_gateway_routes
  blackhole                      = lookup(each.value, "blackhole", null)
  destination_cidr_block         = each.value.destination
  transit_gateway_attachment_id  = tobool(lookup(each.value, "blackhole", false)) == false ? local.vpc_attachment_ids[each.value.attach_name] : null
  transit_gateway_route_table_id = coalesce(lookup(each.value, "route_table_id", null), local.route_table_ids[each.value.route_table_name])
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
