locals {
  vpc_ids = [
    module.vpc_1.vpc_id,
    module.vpc_2.vpc_id,
    module.vpc_3.vpc_id,
  ]
  core_vpc_ids = [module.vpc_1.vpc_id]
  stub_vpc_ids = [module.vpc_2.vpc_id, module.vpc_3.vpc_id]
  cidr_blocks = [
    module.vpc_1.cidr_block,
    module.vpc_2.cidr_block,
    module.vpc_3.cidr_block,
  ]
  stub_subnet_ids = [
    module.vpc_2.private_subnets.*.id,
    module.vpc_3.private_subnets.*.id,
  ]
  stub1_subnet_ids = module.vpc_2.private_subnets.*.id
  stub2_subnet_ids = module.vpc_3.private_subnets.*.id
  core_subnet_ids = [
    module.vpc_1.private_subnets.*.id,
    module.vpc_1.public_subnets.*.id,
  ]
  core_public_subnet_ids    = module.vpc_1.public_subnets.*.id
  core_private_subnet_ids   = module.vpc_1.private_subnets.*.id
  core_pub_route_table_ids  = module.vpc_1.public_route_tables.*.id
  core_priv_route_table_ids = module.vpc_1.private_route_tables.*.id
  core_route_table_ids = concat(
    module.vpc_1.public_route_tables.*.id,
    module.vpc_1.private_route_tables.*.id,
  )
  stub_priv_route_table_ids = concat(
    module.vpc_2.private_route_tables.*.id,
    module.vpc_3.private_route_tables.*.id,
  )
  stub_route_table_ids = concat(
    module.vpc_2.private_route_tables.*.id,
    module.vpc_3.private_route_tables.*.id,
  )
}
