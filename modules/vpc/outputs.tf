### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpc_id" {
  value = local.vpc_id
}

output "vpc_cidr" {
  value = local.vpc_cidr
}

output "inet_gw_id" {
  value = local.inet_gw_id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "public_route_table_ids" {
  value = local.public_route_table_ids
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "private_route_table_ids" {
  value = local.private_route_table_ids
}

output "intra_subnet_ids" {
  value = local.intra_subnet_ids
}

output "intra_route_table_ids" {
  value = local.intra_route_table_ids
}
