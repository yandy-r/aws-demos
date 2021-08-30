module "tgw" {
  source              = "./transit-gw"
  self_public_ip      = var.self_public_ip
  priv_ssh_key_path   = var.priv_ssh_key_path
  domain_name         = var.domain_name_east
  create_flow_logs    = var.create_flow_logs
  create_vpc_endpoint = var.create_vpc_endpoint
  bucket_name         = var.bucket_name

  vpc_cidr_blocks = [
    "10.240.0.0/16",
    "10.241.0.0/16",
    "10.242.0.0/16",
    "10.243.0.0/16"
  ]

  hostnames = [
    "hub-bastion",
    "hub-private",
    "spoke-1",
    "spoke-2",
    "spoke-3"
  ]
}

locals {
  subnets         = module.tgw.subnets
  private_subnets = module.tgw.subnets.private
  public_subnets  = module.tgw.subnets.public
}

output "vpc_info" {
  value = [
    for v in module.tgw.vpcs : {
      name       = v.tags_all.Name
      id         = v.id,
      cidr_block = v.cidr_block
    }
  ]
}

output "subnets" {
  value = {
    for k, v in module.tgw.subnets : k => [
      for i in v : {
        name              = i.tags_all.Name
        id                = i.id
        vpc_id            = i.vpc_id
        cidr_block        = i.cidr_block
        availability_zone = i.availability_zone
      }
    ]
  }
}

output "private_subnets" {
  value = [
    for v in local.private_subnets : {
      name              = v.tags_all.Name
      id                = v.id
      vpc_id            = v.vpc_id
      cidr_block        = v.cidr_block
      availability_zone = v.availability_zone
    }
  ]
}

output "public_subnets" {
  value = [
    for v in local.public_subnets : {
      name              = v.tags_all.Name
      id                = v.id
      vpc_id            = v.vpc_id
      cidr_block        = v.cidr_block
      availability_zone = v.availability_zone
    }
  ]
}
