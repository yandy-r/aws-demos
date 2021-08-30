### -------------------------------------------------------------------------------------------- ###
### VPC
### -------------------------------------------------------------------------------------------- ###

output "vpcs" {
  value = aws_vpc.vpcs
}

output "subnets" {
  value = {
    private = aws_subnet.private,
    public  = aws_subnet.public
  }
}

output "route_tables" {
  value = {
    private = aws_route_table.private,
    public  = aws_route_table.public
  }
}

### -------------------------------------------------------------------------------------------- ###
### EC2 INSTANCES
### -------------------------------------------------------------------------------------------- ###

output "public_ip" {
  value = aws_instance.hub_public.public_ip
}

output "private_ips" {
  value = {
    for i in aws_instance.private :
    i.id => i.private_ip
  }
}
