### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpc_id" {
  value = local.vpc_id
}

output "cidr_block" {
  value = local.cidr_block
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

output "public_subnet_cidr_blocks" {
  value = local.public_subnet_cidr_blocks
}

output "public_route_table_id" {
  value = local.public_route_table_id
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "private_subnet_cidr_blocks" {
  value = local.private_subnet_cidr_blocks
}

output "private_route_table_id" {
  value = local.private_route_table_id
}

output "intra_subnet_ids" {
  value = local.intra_subnet_ids
}

output "intra_subnet_cidr_blocks" {
  value = local.intra_subnet_cidr_blocks
}

output "intra_route_table_id" {
  value = local.intra_route_table_id
}

output "route_table_ids" {
  value = local.route_table_ids
}

output "security_group_ids" {
  value = local.security_group_ids
}
