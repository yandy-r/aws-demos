module "tgw_east" {
  source              = "./transit-gw"
  providers           = { aws = aws.us_east_1 }
  self_public_ip      = var.self_public_ip
  priv_ssh_key_path   = var.priv_ssh_key_path
  domain_name         = var.domain_name_east
  create_flow_logs    = var.create_flow_logs
  create_vpc_endpoint = var.create_vpc_endpoint
  bucket_name         = "east-1-${var.bucket_name}"
  region              = "us-east-1"

  vpc_cidr_blocks = [
    "10.200.0.0/16",
    "10.201.0.0/16",
    "10.202.0.0/16",
    "10.203.0.0/16"
  ]

  hostnames = [
    "hub-e-bastion",
    "hub-e-private",
    "spoke-e-1",
    "spoke-e-2",
    "spoke-e-3"
  ]
}

module "tgw_west" {
  source              = "./transit-gw"
  providers           = { aws = aws.us_west_2 }
  self_public_ip      = var.self_public_ip
  priv_ssh_key_path   = var.priv_ssh_key_path
  domain_name         = var.domain_name_east
  create_flow_logs    = var.create_flow_logs
  create_vpc_endpoint = var.create_vpc_endpoint
  bucket_name         = "west2-1-${var.bucket_name}"
  region              = "us-west-2"

  vpc_cidr_blocks = [
    "10.210.0.0/16",
    "10.211.0.0/16",
    "10.212.0.0/16",
    "10.213.0.0/16"
  ]

  hostnames = [
    "hub-w-bastion",
    "hub-w-private",
    "spoke-w-1",
    "spoke-w-2",
    "spoke-w-3"
  ]
}

locals {
  east_subnets         = module.tgw_east.subnets
  private_east_subnets = module.tgw_east.subnets.private
  public_east_subnets  = module.tgw_east.subnets.public
  west_subnets         = module.tgw_west.subnets
  private_west_subnets = module.tgw_west.subnets.private
  public_west_subnets  = module.tgw_west.subnets.public
}

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




# FOR LATER

# output "east_subnets" {
#   value = {
#     for k, v in module.tgw_east.subnets : k => [
#       for i in v : {
#         name              = i.tags_all.Name
#         id                = i.id
#         vpc_id            = i.vpc_id
#         cidr_block        = i.cidr_block
#         availability_zone = i.availability_zone
#       }
#     ]
#   }
# }

# output "private_east_subnets" {
#   value = [
#     for v in local.private_subnets : {
#       name              = v.tags_all.Name
#       id                = v.id
#       vpc_id            = v.vpc_id
#       cidr_block        = v.cidr_block
#       availability_zone = v.availability_zone
#     }
#   ]
# }

# output "public_east_subnets" {
#   value = [
#     for v in local.public_subnets : {
#       name              = v.tags_all.Name
#       id                = v.id
#       vpc_id            = v.vpc_id
#       cidr_block        = v.cidr_block
#       availability_zone = v.availability_zone
#     }
#   ]
# }
