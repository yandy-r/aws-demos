output "vpc" {
  value = aws_vpc.this
}

output "vpc_id" {
  value = aws_vpc.this[0].id
}

output "cidr_block" {
  value = aws_vpc.this[0].cidr_block
}

output "private" {
  value = aws_subnet.private
}

output "public" {
  value = aws_subnet.public
}

output "public_route_tables" {
  value = aws_route_table.public
}

output "private_route_tables" {
  value = aws_route_table.private
}
