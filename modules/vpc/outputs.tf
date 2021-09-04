### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpc_id" {
  value = local.vpc_id
}

output "vpc_cidr" {
  value = local.vpc_cidr
}

output "internet_gateway_id" {
  value = local.internet_gateway_id
}

output "nat_gateway_id" {
  value = local.nat_gateway_id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "public_route_table_id" {
  value = local.public_route_table_id
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "private_route_table_id" {
  value = local.private_route_table_id
}

output "intra_subnet_ids" {
  value = local.intra_subnet_ids
}

output "intra_route_table_id" {
  value = local.intra_route_table_id
}

output "security_group_ids" {
  value = local.security_group_ids
}
