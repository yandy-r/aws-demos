locals {
  core_vpc = aws_vpc.vpcs.*.id[0]
}
