output "tgw_id" {
  description = "The ID of the Transit Gateway"
  value       = concat(aws_ec2_transit_gateway.this[*].id, [""])[0]
}

output "attachments" {
  value = aws_ec2_transit_gateway_vpc_attachment.this[*].id
}

output "route_tables" {
  value = aws_ec2_transit_gateway_route_table.this[*].id
}
