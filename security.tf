locals {
  vpc_ids                   = [module.vpc_1.vpc_id, module.vpc_2.vpc_id, module.vpc_3.vpc_id]
  core_vpc_ids              = [module.vpc_1.vpc_id]
  stub_vpc_ids              = [module.vpc_2.vpc_id, module.vpc_3.vpc_id]
  cidr_blocks               = [module.vpc_1.vpc[0].cidr_block, module.vpc_2.vpc[0].cidr_block, module.vpc_3.vpc[0].cidr_block]
  stub_subnet_ids           = [module.vpc_2.private_subnets[*].id, module.vpc_3.private_subnets[*].id]
  core_subnet_ids           = [module.vpc_1.private_subnets[*].id, module.vpc_1.public_subnets[*].id]
  core_pub_route_table_ids  = module.vpc_1.public_route_tables[*].id
  core_priv_route_table_ids = module.vpc_1.private_route_tables[*].id
  core_route_table_ids      = concat(module.vpc_1.public_route_tables[*].id, module.vpc_1.private_route_tables[*].id)
  stub_priv_route_table_ids = concat(module.vpc_2.private_route_tables[*].id, module.vpc_3.private_route_tables[*].id)
  stub_route_table_ids      = concat(module.vpc_2.private_route_tables[*].id, module.vpc_3.private_route_tables[*].id)
}

resource "aws_security_group" "this" {
  count       = length(local.vpc_ids)
  description = "Security group that allows inter-vpc communication"

  vpc_id = local.vpc_ids[count.index]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress" {
  count             = length(local.vpc_ids)
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.this[count.index].id
  cidr_blocks       = local.cidr_blocks
}

resource "aws_security_group_rule" "allow_home" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = aws_security_group.this[0].id
  cidr_blocks       = [var.home_ip]
}
