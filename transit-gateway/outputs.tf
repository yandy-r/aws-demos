output "tgw_id" {
  description = "The ID of the Transit Gateway"
  value       = concat(aws_ec2_transit_gateway.this[*].id, [""])[0]
}

output "attachment_ids" {
  value = [for k, v in aws_ec2_transit_gateway_vpc_attachment.this : v.id]
}

output "route_tables" {
  value = [for k, v in aws_ec2_transit_gateway_route_table.this : v.id]
}
