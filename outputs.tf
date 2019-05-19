output "vpc_1" {
  value = module.vpc_1.vpc
}

output "vpc_2" {
  value = module.vpc_2.vpc
}

output "vpc_3" {
  value = module.vpc_3.vpc
}

output "vpc_1_id" {
  value = module.vpc_1.vpc_id
}

output "vpc_2_id" {
  value = module.vpc_2.vpc_id
}

output "vpc_3_id" {
  value = module.vpc_3.vpc_id
}

output "core_subnet_ids" {
  value = concat(
    module.vpc_1.private_subnets.*.id,
    module.vpc_1.public_subnets.*.id,
  )
}

output "public_subnets_1" {
  value = module.vpc_1.public_subnets
}

output "private_subnets_1" {
  value = module.vpc_1.private_subnets
}

output "private_subnets_2" {
  value = module.vpc_2.private_subnets
}

output "private_subnets_3" {
  value = module.vpc_3.private_subnets
}
