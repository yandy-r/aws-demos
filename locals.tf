locals {
  core_vpc_ids              = [module.core_vpc.vpc_id]
  spoke_vpc_ids             = [module.spoke_1_vpc.vpc_id, module.spoke_2_vpc.vpc_id]
  spoke_1_subnet_ids        = module.spoke_1_vpc.private_subnets.*.id
  spoke_2_subnet_ids        = module.spoke_2_vpc.private_subnets.*.id
  core_public_subnet_ids    = module.core_vpc.public_subnets.*.id
  core_private_subnet_ids   = module.core_vpc.private_subnets.*.id
  core_pub_route_table_ids  = module.core_vpc.public_route_tables.*.id
  core_priv_route_table_ids = module.core_vpc.private_route_tables.*.id

  vpc_ids = [
    module.core_vpc.vpc_id,
    module.spoke_1_vpc.vpc_id,
    module.spoke_2_vpc.vpc_id,
  ]

  cidr_blocks = [
    module.core_vpc.cidr_block,
    module.spoke_1_vpc.cidr_block,
    module.spoke_2_vpc.cidr_block,
  ]

  spoke_subnet_ids = concat(
    module.spoke_1_vpc.private_subnets.*.id,
    module.spoke_2_vpc.private_subnets.*.id,
  )

  core_subnet_ids = concat(
    module.core_vpc.public_subnets.*.id,
    module.core_vpc.private_subnets.*.id,
  )

  subnet_ids = concat(
    module.core_vpc.public_subnets.*.id,
    module.core_vpc.private_subnets.*.id,
    module.spoke_1_vpc.private_subnets.*.id,
    module.spoke_2_vpc.private_subnets.*.id,
  )

  core_route_table_ids = concat(
    module.core_vpc.public_route_tables.*.id,
    module.core_vpc.private_route_tables.*.id,
  )

  spoke_priv_route_table_ids = concat(
    module.spoke_1_vpc.private_route_tables.*.id,
    module.spoke_2_vpc.private_route_tables.*.id,
  )

  spoke_route_table_ids = concat(
    module.spoke_1_vpc.private_route_tables.*.id,
    module.spoke_2_vpc.private_route_tables.*.id,
  )

  core_sg_ids = [
    aws_security_group.core_public_sg.id,
    aws_security_group.core_private_sg.id,
  ]

  spoke_sg_ids = [
    aws_security_group.spoke_1_private_sg.id,
    aws_security_group.spoke_2_private_sg.id,
  ]
}
