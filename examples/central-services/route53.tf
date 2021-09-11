### -------------------------------------------------------------------------------------------- ###
### EAST ROUTE53
### -------------------------------------------------------------------------------------------- ###

module "east_dns" {
  source    = "../../modules/route53"
  providers = { aws = aws.us_east_1 }
  name      = "east_dns"

  route53_zone = {
    east = {
      name = var.zone_names["east"]
      vpc = {
        east_hub = {
          vpc_id = module.east_hub.vpc_id
        }
      }
    }
  }

  route53_zone_association = {
    spoke1 = {
      zone_id = module.east_dns.zone_ids["east"]
      vpc_id  = module.east_spoke1.vpc_id
    }
    spoke2 = {
      zone_id = module.east_dns.zone_ids["east"]
      vpc_id  = module.east_spoke2.vpc_id
    }
    spoke3 = {
      zone_id = module.east_dns.zone_ids["east"]
      vpc_id  = module.east_spoke3.vpc_id
    }
  }

  route53_record = {
    hub1 = {
      zone_id = module.east_dns.zone_ids["east"]
      name    = "hub_public1.${module.east_dns.zone_names["east"]}"
      records = [module.east_ec2.instance_private_ips["hub_public1"]]
      type    = "A"
      ttl     = "300"
    }
    hub_private1 = {
      zone_id = module.east_dns.zone_ids["east"]
      name    = "hub_private1.${module.east_dns.zone_names["east"]}"
      records = [module.east_ec2.instance_private_ips["hub_private1"]]
      type    = "A"
      ttl     = "300"
    }
    spoke1 = {
      zone_id = module.east_dns.zone_ids["east"]
      name    = "spoke1.${module.east_dns.zone_names["east"]}"
      records = [module.east_ec2.instance_private_ips["spoke1"]]
      type    = "A"
      ttl     = "300"
    }
    spoke2 = {
      zone_id = module.east_dns.zone_ids["east"]
      name    = "spoke2.${module.east_dns.zone_names["east"]}"
      records = [module.east_ec2.instance_private_ips["spoke2"]]
      type    = "A"
      ttl     = "300"
    }
    spoke3 = {
      zone_id = module.east_dns.zone_ids["east"]
      name    = "spoke3.${module.east_dns.zone_names["east"]}"
      records = [module.east_ec2.instance_private_ips["spoke3"]]
      type    = "A"
      ttl     = "300"
    }
  }

  security_groups = {
    endpoints = {
      vpc_id      = module.east_hub.vpc_id
      description = "Attached to inbound resolver"

      egress = [{
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }]

      ingress = [{
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = [
          var.cidr_blocks.east["supernet"],
          var.cidr_blocks.west["supernet"],
          var.lab_local_cidr
        ]
      }]
    }
  }

  resolver_endpoint = {
    inbound = {
      name               = "east_inbound"
      direction          = "INBOUND"
      security_group_ids = [module.east_dns.security_group_ids["endpoints"]]

      ip_address = [
        {
          subnet_id = module.east_hub.private_subnet_ids[0]
          ip        = cidrhost(module.east_hub.private_subnet_cidr_blocks[0], 4)
        },
        {
          subnet_id = module.east_hub.private_subnet_ids[1]
          ip        = cidrhost(module.east_hub.private_subnet_cidr_blocks[1], 4)
        }
      ]
    }
    outbound = {
      name               = "east_outbound"
      direction          = "OUTBOUND"
      security_group_ids = [module.east_dns.security_group_ids["endpoints"]]

      ip_address = [
        {
          subnet_id = module.east_hub.private_subnet_ids[0]
          ip        = cidrhost(module.east_hub.private_subnet_cidr_blocks[0], 5)
        },
        {
          subnet_id = module.east_hub.private_subnet_ids[1]
          ip        = cidrhost(module.east_hub.private_subnet_cidr_blocks[1], 5)
        }
      ]
    }
  }

  resolver_rule = {
    outbound = {
      name                 = "east_outbound"
      domain_name          = var.lab_domain_name
      rule_type            = "FORWARD"
      resolver_endpoint_id = module.east_dns.resolver_endpoint_ids["outbound"]

      target_ip = [{
        ip   = var.lab_dns_server
        port = "53"
        }
      ]
    }
  }
  resolver_rule_association = [
    {
      resolver_rule_id = module.east_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.east_hub.vpc_id
    },
    {
      resolver_rule_id = module.east_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.east_spoke1.vpc_id
    },
    {
      resolver_rule_id = module.east_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.east_spoke2.vpc_id
    },
    {
      resolver_rule_id = module.east_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.east_spoke3.vpc_id
    },
  ]
}

### -------------------------------------------------------------------------------------------- ###
### WEST ROUTE53
### -------------------------------------------------------------------------------------------- ###

module "west_dns" {
  source    = "../../modules/route53"
  providers = { aws = aws.us_west_2 }
  name      = "west_dns"

  route53_zone = {
    west = {
      name = var.zone_names["west"]
      vpc = {
        hub = {
          vpc_id = module.west_hub.vpc_id
        }
      }
    }
  }

  route53_zone_association = {
    spoke1 = {
      zone_id = module.west_dns.zone_ids["west"]
      vpc_id  = module.west_spoke1.vpc_id
    }
    spoke2 = {
      zone_id = module.west_dns.zone_ids["west"]
      vpc_id  = module.west_spoke2.vpc_id
    }
    spoke3 = {
      zone_id = module.west_dns.zone_ids["west"]
      vpc_id  = module.west_spoke3.vpc_id
    }
  }

  route53_record = {
    hub1 = {
      zone_id = module.west_dns.zone_ids["west"]
      name    = "hub_public1.${module.west_dns.zone_names["west"]}"
      records = [module.west_ec2.instance_private_ips["hub_public1"]]
      type    = "A"
      ttl     = "300"
    }
    hub_private1 = {
      zone_id = module.west_dns.zone_ids["west"]
      name    = "hub_private1.${module.west_dns.zone_names["west"]}"
      records = [module.west_ec2.instance_private_ips["hub_private1"]]
      type    = "A"
      ttl     = "300"
    }
    spoke1 = {
      zone_id = module.west_dns.zone_ids["west"]
      name    = "spoke1.${module.west_dns.zone_names["west"]}"
      records = [module.west_ec2.instance_private_ips["spoke1"]]
      type    = "A"
      ttl     = "300"
    }
    spoke2 = {
      zone_id = module.west_dns.zone_ids["west"]
      name    = "spoke2.${module.west_dns.zone_names["west"]}"
      records = [module.west_ec2.instance_private_ips["spoke2"]]
      type    = "A"
      ttl     = "300"
    }
    spoke3 = {
      zone_id = module.west_dns.zone_ids["west"]
      name    = "spoke3.${module.west_dns.zone_names["west"]}"
      records = [module.west_ec2.instance_private_ips["spoke3"]]
      type    = "A"
      ttl     = "300"
    }
  }

  security_groups = {
    endpoints = {
      vpc_id      = module.west_hub.vpc_id
      description = "Attached to inbound resolver"

      egress = [{
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }]

      ingress = [{
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = [
          var.cidr_blocks.east["supernet"],
          var.cidr_blocks.west["supernet"],
          var.lab_local_cidr
        ]
      }]
    }
  }

  resolver_endpoint = {
    inbound = {
      name               = "west_inbound"
      direction          = "INBOUND"
      security_group_ids = [module.west_dns.security_group_ids["endpoints"]]

      ip_address = [
        {
          subnet_id = module.west_hub.private_subnet_ids[0]
          ip        = cidrhost(module.west_hub.private_subnet_cidr_blocks[0], 4)
        },
        {
          subnet_id = module.west_hub.private_subnet_ids[1]
          ip        = cidrhost(module.west_hub.private_subnet_cidr_blocks[1], 4)
        }
      ]
    }
    outbound = {
      name               = "west_outbound"
      direction          = "OUTBOUND"
      security_group_ids = [module.west_dns.security_group_ids["endpoints"]]

      ip_address = [
        {
          subnet_id = module.west_hub.private_subnet_ids[0]
          ip        = cidrhost(module.west_hub.private_subnet_cidr_blocks[0], 5)
        },
        {
          subnet_id = module.west_hub.private_subnet_ids[1]
          ip        = cidrhost(module.west_hub.private_subnet_cidr_blocks[1], 5)
        }
      ]
    }
  }

  resolver_rule = {
    outbound = {
      name                 = "west_outbound"
      domain_name          = var.lab_domain_name
      rule_type            = "FORWARD"
      resolver_endpoint_id = module.west_dns.resolver_endpoint_ids["outbound"]

      target_ip = [{
        ip   = var.lab_dns_server
        port = "53"
        }
      ]
    }
  }
  resolver_rule_association = [
    {
      resolver_rule_id = module.west_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.west_hub.vpc_id
    },
    {
      resolver_rule_id = module.west_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.west_spoke1.vpc_id
    },
    {
      resolver_rule_id = module.west_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.west_spoke2.vpc_id
    },
    {
      resolver_rule_id = module.west_dns.resolver_rule_ids["outbound"]
      vpc_id           = module.west_spoke3.vpc_id
    },
  ]
}
