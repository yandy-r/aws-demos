### -------------------------------------------------------------------------------------------- ###
### EAST VPN
### -------------------------------------------------------------------------------------------- ###

module "east_vpn" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_east_1 }
  name      = "east_vpn"

  customer_gateway = {
    east_vpn = {
      bgp_asn     = var.customer_side_asn
      device_name = "east_vpn"
      ip_address  = var.lab_public_ip
      type        = "ipsec.1"
    }
  }

  vpn_connection = {
    east_vpn = {
      transit_gateway_id                   = module.east_transit_gateway.transit_gateway_id
      static_routes_only                   = false
      tunnel1_preshared_key                = var.tunnel1_preshared_key
      tunnel2_preshared_key                = var.tunnel2_preshared_key
      tunnel1_inside_cidr                  = "169.254.200.0/30"
      tunnel2_inside_cidr                  = "169.254.200.4/30"
      tunnel1_ike_versions                 = ["ikev2"]
      tunnel2_ike_versions                 = ["ikev2"]
      tunnel1_phase1_dh_group_numbers      = ["14"]
      tunnel2_phase1_dh_group_numbers      = ["14"]
      tunnel1_phase1_integrity_algorithms  = ["SHA1"]
      tunnel2_phase1_integrity_algorithms  = ["SHA1"]
      tunnel1_phase1_encryption_algorithms = ["AES128"]
      tunnel2_phase1_encryption_algorithms = ["AES128"]
      tunnel1_phase2_dh_group_numbers      = ["14"]
      tunnel2_phase2_dh_group_numbers      = ["14"]
      tunnel1_phase2_integrity_algorithms  = ["SHA1"]
      tunnel2_phase2_integrity_algorithms  = ["SHA1"]
      tunnel1_phase2_encryption_algorithms = ["AES128"]
      tunnel2_phase2_encryption_algorithms = ["AES128"]
    }
  }

  transit_gateway_route_tables = {
    east_vpn = {
      transit_gateway_id = module.east_transit_gateway.transit_gateway_id
    }
  }
  transit_gateway_route_table_associations = {
    east_vpn = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
  }
  transit_gateway_route_table_propagations = {
    vpn_to_hubs = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    }
    vpn_to_spokes = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    }
    vpn_to_east_west = {
      transit_gateway_attachment_id  = module.east_vpn.vpn_transit_gateway_attachment_ids["east_vpn"]
      transit_gateway_route_table_id = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    hub_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
    spoke1_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
    spoke2_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
    spoke3_to_east_vpn = {
      transit_gateway_attachment_id  = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      transit_gateway_route_table_id = module.east_vpn.transit_gateway_route_table_ids["east_vpn"]
    }
  }

  vpc_routes = [
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.east_hub.public_route_table_id
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.east_hub.private_route_table_id
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.east_hub.intra_route_table_id
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
    }
  ]

  security_group_rules = [
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_hub.security_group_ids["private1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_hub.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_spoke1.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_spoke2.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.east_spoke3.security_group_ids["intra1"]
    },
  ]
}

### -------------------------------------------------------------------------------------------- ###
### WEST VPN
### -------------------------------------------------------------------------------------------- ###

module "west_vpn" {
  source    = "../../modules/vpc"
  providers = { aws = aws.us_west_2 }
  name      = "west_vpn"

  customer_gateway = {
    west_vpn = {
      bgp_asn     = var.customer_side_asn
      device_name = "west_vpn"
      ip_address  = var.lab_public_ip
      type        = "ipsec.1"
    }
  }

  vpn_connection = {
    west_vpn = {
      transit_gateway_id                   = module.west_transit_gateway.transit_gateway_id
      static_routes_only                   = false
      tunnel1_preshared_key                = var.tunnel1_preshared_key
      tunnel2_preshared_key                = var.tunnel2_preshared_key
      tunnel1_inside_cidr                  = "169.254.220.0/30"
      tunnel2_inside_cidr                  = "169.254.220.4/30"
      tunnel1_ike_versions                 = ["ikev2"]
      tunnel2_ike_versions                 = ["ikev2"]
      tunnel1_phase1_dh_group_numbers      = ["14"]
      tunnel2_phase1_dh_group_numbers      = ["14"]
      tunnel1_phase1_integrity_algorithms  = ["SHA1"]
      tunnel2_phase1_integrity_algorithms  = ["SHA1"]
      tunnel1_phase1_encryption_algorithms = ["AES128"]
      tunnel2_phase1_encryption_algorithms = ["AES128"]
      tunnel1_phase2_dh_group_numbers      = ["14"]
      tunnel2_phase2_dh_group_numbers      = ["14"]
      tunnel1_phase2_integrity_algorithms  = ["SHA1"]
      tunnel2_phase2_integrity_algorithms  = ["SHA1"]
      tunnel1_phase2_encryption_algorithms = ["AES128"]
      tunnel2_phase2_encryption_algorithms = ["AES128"]
    }
  }

  transit_gateway_route_tables = {
    west_vpn = {
      transit_gateway_id = module.west_transit_gateway.transit_gateway_id
    }
  }
  transit_gateway_route_table_associations = {
    west_vpn = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
  }
  transit_gateway_route_table_propagations = {
    vpn_to_hubs = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    }
    vpn_to_spokes = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    }
    vpn_to_east_west = {
      transit_gateway_attachment_id  = module.west_vpn.vpn_transit_gateway_attachment_ids["west_vpn"]
      transit_gateway_route_table_id = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    hub_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
    spoke1_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
    spoke2_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
    spoke3_to_west_vpn = {
      transit_gateway_attachment_id  = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      transit_gateway_route_table_id = module.west_vpn.transit_gateway_route_table_ids["west_vpn"]
    }
  }

  vpc_routes = [
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.west_hub.public_route_table_id
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.west_hub.private_route_table_id
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
    },
    {
      destination_cidr_block = var.lab_local_cidr
      route_table_id         = module.west_hub.intra_route_table_id
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
    }
  ]

  security_group_rules = [
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_hub.security_group_ids["public1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_hub.security_group_ids["private1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_hub.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_spoke1.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_spoke2.security_group_ids["intra1"]
    },
    {
      description       = "Allow ALL sourced from home lab"
      type              = "ingress"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = [cidrsubnet(var.lab_local_cidr, 5, 0)]
      security_group_id = module.west_spoke3.security_group_ids["intra1"]
    },
  ]
}
