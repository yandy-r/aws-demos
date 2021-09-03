### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpc" {
  value = local.vpc
}

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
  value = local.public_subnet_ids
}

# output "private_subnet_ids" {
#   value = aws_subnet.private[*].id
# }

# output "intra_subnet_ids" {
#   value = aws_subnet.intra[*].id
# }

# output "public_subnets" {
#   value = [for v in aws_subnet.public : v]
# }

# output "private_subnets" {
#   value = aws_subnet.private[*]
# }

# output "intra_subnets" {
#   value = aws_subnet.intra[*]
# }

# output "public_route_table" {
#   value = aws_route_table.public[*].id
# }

# output "private_route_table" {
#   value = aws_route_table.private[*].id
# }

# output "intra_route_table" {
#   value = aws_route_table.intra[*].id
# }

# output "igw_id" {
#   description = "The ID of the Internet Gateway"
#   value       = concat(aws_internet_gateway.this[*].id, [""])[0]
# }

# output "natgw_id" {
#   description = "The ID of the NAT Gateway"
#   value       = aws_nat_gateway.this[*].id
# }
