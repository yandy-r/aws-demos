output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = local.transit_gateway_id
}

output "vpc_attachment_ids" {
  value = local.vpc_attachment_ids
}

output "route_table_ids" {
  value = local.route_table_ids
}

output "transit_gateway_peering_attachment_ids" {
  value = local.transit_gateway_peering_attachment_ids
}

output "transit_gateway_peering_attachment_accepter_ids" {
  value = local.transit_gateway_peering_attachment_accepter_ids
}
