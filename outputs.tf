# output "public_east_ec2" {
#   value = [for v in module.tgw_east.public_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     public_ip  = v.public_ip
#     } if v.public_ip != ""
#   ]
# }

# output "private_east_ec2" {
#   value = [for v in module.tgw_east.private_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     }
#   ]
# }

# output "public_west_ec2" {
#   value = [for v in module.tgw_west.public_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     public_ip  = v.public_ip
#     } if v.public_ip != ""
#   ]
# }

# output "private_west_ec2" {
#   value = [for v in module.tgw_west.private_instances : {
#     name       = v.tags_all.Name
#     id         = v.id
#     private_ip = v.private_ip
#     }
#   ]
# }

# output "vpc_east_info" {
#   value = [
#     for v in module.tgw_east.vpcs : {
#       name       = v.tags_all.Name
#       id         = v.id,
#       cidr_block = v.cidr_block
#     }
#   ]
# }

# output "vpc_west_info" {
#   value = [
#     for v in module.tgw_west.vpcs : {
#       name       = v.tags_all.Name
#       id         = v.id,
#       cidr_block = v.cidr_block
#     }
#   ]
# }

# # FOR LATER

# # output "east_subnets" {
# #   value = {
# #     for k, v in module.tgw_east.subnets : k => [
# #       for i in v : {
# #         name              = i.tags_all.Name
# #         id                = i.id
# #         vpc_id            = i.vpc_id
# #         cidr_block        = i.cidr_block
# #         availability_zone = i.availability_zone
# #       }
# #     ]
# #   }
# # }

# # output "private_east_subnets" {
# #   value = [
# #     for v in local.private_subnets : {
# #       name              = v.tags_all.Name
# #       id                = v.id
# #       vpc_id            = v.vpc_id
# #       cidr_block        = v.cidr_block
# #       availability_zone = v.availability_zone
# #     }
# #   ]
# # }

# # output "public_east_subnets" {
# #   value = [
# #     for v in local.public_subnets : {
# #       name              = v.tags_all.Name
# #       id                = v.id
# #       vpc_id            = v.vpc_id
# #       cidr_block        = v.cidr_block
# #       availability_zone = v.availability_zone
# #     }
# #   ]
# # }
