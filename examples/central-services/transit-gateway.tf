### -------------------------------------------------------------------------------------------- ###
### EAST TRANSIT GATEWAY
### -------------------------------------------------------------------------------------------- ###

module "east_transit_gateway" {
  source    = "../../modules/transit-gateway"
  providers = { aws = aws.us_east_1 }
  name      = "east"

  transit_gateway = [{
    dns_support                     = "enable"
    description                     = "US East Transit Gateway"
    amazon_side_asn                 = var.amzn_side_asn
    vpn_ecmp_support                = "enable"
    auto_accept_shared_attachments  = "disable"
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    tags                            = { Purpose = "Central routing hub for the east" }
  }]

  vpc_attachments = {
    hub1 = {
      vpc_id                                          = module.east_hub.vpc_id
      subnet_ids                                      = module.east_hub.private_subnet_ids
      dns_support                                     = "enable"
      ipv6_support                                    = "disable"
      appliance_mode_support                          = "disable"
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags                                            = { Purpose = "Attachment to Hub1 VPC" }
    }
    spoke1 = {
      vpc_id     = module.east_spoke1.vpc_id
      subnet_ids = module.east_spoke1.intra_subnet_ids
    }
    spoke2 = {
      vpc_id     = module.east_spoke2.vpc_id
      subnet_ids = module.east_spoke2.intra_subnet_ids
    }
    spoke3 = {
      vpc_id     = module.east_spoke3.vpc_id
      subnet_ids = module.east_spoke3.intra_subnet_ids
    }
  }

  transit_gateway_peering_attachment = {
    east_to_west = {
      peer_region             = "us-west-2"
      transit_gateway_id      = module.east_transit_gateway.transit_gateway_id
      peer_transit_gateway_id = module.west_transit_gateway.transit_gateway_id
    }
  }

  route_tables = {
    hubs         = {}
    spokes       = {}
    east_to_west = {}
  }

  route_table_associations = {
    hub1 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke1 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke2 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke3 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    east_to_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
  }

  route_table_propagations = {
    hub_to_spokes = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke_1_to_hub = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke_2_to_hub = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke_3_to_hub = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
    }
    spoke_1_to_2 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    spoke_2_to_1 = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    }
    hub_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke1_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke2_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke3_to_east_west = {
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.east_transit_gateway.route_table_ids["east_to_west"]
    }
  }

  transit_gateway_routes = [
    {
      destination                   = "0.0.0.0/0"
      transit_gateway_attachment_id = module.east_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination                   = var.cidr_blocks.west["supernet"]
      route_table_id                = module.east_transit_gateway.route_table_ids["hubs"]
      transit_gateway_attachment_id = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
    },
    {
      destination                   = var.cidr_blocks.west["supernet"]
      route_table_id                = module.east_transit_gateway.route_table_ids["spokes"]
      transit_gateway_attachment_id = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.east_transit_gateway.route_table_ids["spokes"]
    }
  ]

  vpc_routes = [
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_hub.public_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_hub.private_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_hub.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke1.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke2.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.east_transit_gateway.transit_gateway_id
      route_table_id         = module.east_spoke3.intra_route_table_id
    },
  ]
}

### -------------------------------------------------------------------------------------------- ###
### WEST TRANSIT GATEWAY
### -------------------------------------------------------------------------------------------- ###

module "west_transit_gateway" {
  source    = "../../modules/transit-gateway"
  providers = { aws = aws.us_west_2 }
  name      = "west"

  transit_gateway = [{
    dns_support                     = "enable"
    description                     = "US East Transit Gateway"
    amazon_side_asn                 = var.amzn_side_asn
    vpn_ecmp_support                = "enable"
    auto_accept_shared_attachments  = "disable"
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    tags                            = { Purpose = "Central routing hub for the west" }
  }]

  vpc_attachments = {
    hub1 = {
      vpc_id                                          = module.west_hub.vpc_id
      subnet_ids                                      = module.west_hub.private_subnet_ids
      dns_support                                     = "enable"
      ipv6_support                                    = "disable"
      appliance_mode_support                          = "disable"
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      tags                                            = { Purpose = "Attachment to Hub1 VPC" }
    }
    spoke1 = {
      vpc_id     = module.west_spoke1.vpc_id
      subnet_ids = module.west_spoke1.intra_subnet_ids
    }
    spoke2 = {
      vpc_id     = module.west_spoke2.vpc_id
      subnet_ids = module.west_spoke2.intra_subnet_ids
    }
    spoke3 = {
      vpc_id     = module.west_spoke3.vpc_id
      subnet_ids = module.west_spoke3.intra_subnet_ids
    }
  }

  transit_gateway_peering_attachment_accepter = {
    east_to_west = {
      transit_gateway_peering_attachment = module.east_transit_gateway.transit_gateway_peering_attachment_ids["east_to_west"]
    }
  }

  route_tables = {
    hubs         = {}
    spokes       = {}
    east_to_west = {}
  }

  route_table_associations = {
    hub1 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke1 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke2 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke3 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    east_to_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.transit_gateway_peering_attachment_accepter_ids["east_to_west"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
  }

  route_table_propagations = {
    hub_to_spokes = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke_1_to_hub = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke_2_to_hub = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke_3_to_hub = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
    }
    spoke_1_to_2 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    spoke_2_to_1 = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
    }
    hub_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke1_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke1"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke2_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke2"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
    spoke3_to_east_west = {
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["spoke3"]
      route_table_id                = module.west_transit_gateway.route_table_ids["east_to_west"]
    }
  }

  transit_gateway_routes = [
    {
      destination                   = "0.0.0.0/0"
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
      transit_gateway_attachment_id = module.west_transit_gateway.vpc_attachment_ids["hub1"]
    },
    {
      destination                   = var.cidr_blocks.east["supernet"]
      route_table_id                = module.west_transit_gateway.route_table_ids["hubs"]
      transit_gateway_attachment_id = module.west_transit_gateway.transit_gateway_peering_attachment_accepter_ids["east_to_west"]
    },
    {
      destination                   = var.cidr_blocks.east["supernet"]
      route_table_id                = module.west_transit_gateway.route_table_ids["spokes"]
      transit_gateway_attachment_id = module.west_transit_gateway.transit_gateway_peering_attachment_accepter_ids["east_to_west"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "10.0.0.0/8"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "172.16.0.0/12"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["hubs"]
    },
    {
      destination    = "192.168.0.0/16"
      blackhole      = true
      route_table_id = module.west_transit_gateway.route_table_ids["spokes"]
    }
  ]

  vpc_routes = [
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_hub.public_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_hub.private_route_table_id
    },
    {
      destination_cidr_block = "10.192.0.0/11"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_hub.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke1.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke2.intra_route_table_id
    },
    {
      destination_cidr_block = "0.0.0.0/0"
      transit_gateway_id     = module.west_transit_gateway.transit_gateway_id
      route_table_id         = module.west_spoke3.intra_route_table_id
    },
  ]
}
