### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpc" {
  value = aws_vpc.this[0].id
}

output "vpc_id" {
  value = aws_vpc.this[0].id
}

output "vpc_cidr" {
  value = aws_vpc.this[0].cidr_block
}

output "vpc_arn" {
  value = aws_vpc.this[0].arn
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "intra_subnet_ids" {
  value = aws_subnet.intra[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*]
}

output "private_subnets" {
  value = aws_subnet.private[*]
}

output "intra_subnets" {
  value = aws_subnet.intra[*]
}

output "public_route_table" {
  value = aws_route_table.public[*].id
}

output "private_route_table" {
  value = aws_route_table.private[*].id
}

output "intra_route_table" {
  value = aws_route_table.intra[*].id
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = concat(aws_internet_gateway.this[*].id, [""])[0]
}

output "natgw_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this[*].id
}
