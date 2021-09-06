output "tgw_id" {
  description = "The ID of the Transit Gateway"
  value       = local.transit_gateway_id
}

output "attachment_ids" {
  value = local.vpc_attachment_ids
}

output "route_tables" {
  value = local.route_table_ids
}
