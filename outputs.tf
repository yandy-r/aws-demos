output "core_vpc" {
  value = module.core_vpc.vpc
}

output "spoke_1_vpc" {
  value = module.spoke_1_vpc.vpc
}

output "spoke_2_vpc" {
  value = module.spoke_2_vpc.vpc
}

output "core_vpc_id" {
  value = module.core_vpc.vpc_id
}

output "spoke_1_vpc_id" {
  value = module.spoke_1_vpc.vpc_id
}

output "spoke_2_vpc_id" {
  value = module.spoke_2_vpc.vpc_id
}

output "core_subnet_ids" {
  value = concat(
    module.core_vpc.private_subnets.*.id,
    module.core_vpc.public_subnets.*.id,
  )
}

output "public_subnets_1" {
  value = module.core_vpc.public_subnets
}

output "private_subnets_1" {
  value = module.core_vpc.private_subnets
}

output "private_subnets_2" {
  value = module.spoke_1_vpc.private_subnets
}

output "private_subnets_3" {
  value = module.spoke_2_vpc.private_subnets
}
