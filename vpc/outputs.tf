### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpc" {
  value = aws_vpc.this
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "vpc_arn" {
  value = aws_vpc.this.arn
}

output "public_subnets" {
  value = concat(aws_subnet.public.*.id, [""])[0]
}

output "private_subnets" {
  value = concat(aws_subnet.private.*.id, [""])[0]
}

output "intra_subnets" {
  value = concat(aws_subnet.intra.*.id, [""])[0]
}

output "public_route_table" {
  value = concat(aws_route_table.public.*.id, [""])[0]
}

output "private_route_table" {
  value = concat(aws_route_table.private.*.id, [""])[0]
}

output "intra_route_table" {
  value = concat(aws_route_table.intra.*.id, [""])[0]
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = concat(aws_internet_gateway.this.*.id, [""])[0]
}

output "natgw_id" {
  description = "The ID of the NAT Gateway"
  value       = concat(aws_nat_gateway.this.*.id, [""])[0]
}

output "tgw_id" {
  description = "The ID of the Transit Gateway"
  value       = concat(aws_ec2_transit_gateway.this.*.id, [""])[0]
}
