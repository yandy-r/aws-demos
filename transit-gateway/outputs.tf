output "tgw_id" {
  description = "The ID of the Transit Gateway"
  value       = concat(aws_ec2_transit_gateway.this.*.id, [""])[0]
}
