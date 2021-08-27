output "core_vpc" {
  value = module.core_vpc.vpc
}

output "spoke_1_vpc" {
  value = module.spoke_1_vpc.vpc
}

output "spoke_2_vpc" {
  value = module.spoke_2_vpc.vpc
}

output "spoke_3_vpc" {
  value = module.spoke_3_vpc.vpc
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

output "spoke_3_vpc_id" {
  value = module.spoke_3_vpc.vpc_id
}

output "core_subnet_ids" {
  value = concat(
    module.core_vpc.private_subnets.*.id,
    module.core_vpc.public_subnets.*.id,
  )
}

output "core_public_subnets" {
  value = module.core_vpc.public_subnets
}

output "core_private_subnets" {
  value = module.core_vpc.private_subnets
}

output "spoke_1_private_subnets" {
  value = module.spoke_1_vpc.private_subnets
}

output "spoke_2_private_subnets" {
  value = module.spoke_2_vpc.private_subnets
}

output "spoke_3_private_subnets" {
  value = module.spoke_3_vpc.private_subnets
}
