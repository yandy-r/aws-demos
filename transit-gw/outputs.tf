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

output "aws_region" {
  value = data.aws_region.current.name
}

### -------------------------------------------------------------------------------------------- ###
### EC2 INSTANCES
### -------------------------------------------------------------------------------------------- ###

output "public_instances" {
  value = aws_instance.hub_public
}

output "private_instances" {
  value = aws_instance.private
}

### -------------------------------------------------------------------------------------------- ###
### TRANSIT GATEWAY
### -------------------------------------------------------------------------------------------- ###

output "tgw" {
  value = aws_ec2_transit_gateway.tgw
}

output "tgw_rts" {
  value = [
    aws_ec2_transit_gateway_route_table.hub[0],
    aws_ec2_transit_gateway_route_table.spokes[0]
  ]
}
