provider "aws" {
}

## Core VPC
module "core_vpc" {
  source = "git::ssh://git@github.com/IPyandy/terraform-aws-modules.git//vpc?ref=terraform-0.12"

  ### VPC
  create_vpc = true

  azs = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  cidr_block                      = "10.244.0.0/16"
  instance_tenancy                = "default"
  enable_dns_hostnames            = true
  enable_dns_support              = true
  enable_classic_link             = false
  enable_classic_link_dns_support = false

  ### DHCP OPTIONS
  create_dhcp_options      = true
  dhcp_domain_name         = var.domain_name
  dhcp_domain_name_servers = ["AmazonProvidedDNS"]

  dhcp_ntp_servers = [
    "69.195.159.158",
    "173.255.206.153",
  ]

  dhcp_netbios_name_servers = []
  dhcp_netbios_node_type    = 2

  #############################################################################
  ### IPv4 SUBNETS
  #############################################################################

  map_public      = true
  num_pub_subnets = 1
  pub_subnet_tags = [
    {
      Name = "Core-VPC-Public-Subnet"
    },
  ]
  num_priv_subnets = 1
  priv_subnet_tags = [
    {
      Name = "Core-VPC-Private-Subnet-1"
    },
  ]
  ipv4_priv_newbits = 8
  ipv4_priv_netnum  = 128

  ### ROUTING AND INTERNET
  #############################################################################

  create_inet_gw = true
  num_nat_gws    = 1

  #############################################################################
  ### FLOWLOGS
  #############################################################################

  create_flow_log     = true
  flow_log_group_name = "Core-VPC-flowlog"

  #############################################################################
  ### ALL TAGS
  #############################################################################

  vpc_tags = {
    Name = "Core-VPC"
  }
}

## Spoke 1 VPC

module "spoke_1_vpc" {
  source = "git::ssh://git@github.com/IPyandy/terraform-aws-modules.git//vpc?ref=terraform-0.12"

  ### VPC
  create_vpc = true

  azs = [
    "us-east-1d",
    "us-east-1e",
    "us-east-1f",
  ]

  cidr_block                      = "10.245.0.0/16"
  instance_tenancy                = "default"
  enable_dns_hostnames            = true
  enable_dns_support              = true
  enable_classic_link             = false
  enable_classic_link_dns_support = false

  ### DHCP OPTIONS
  create_dhcp_options      = true
  dhcp_domain_name         = var.domain_name
  dhcp_domain_name_servers = ["AmazonProvidedDNS"]

  dhcp_ntp_servers = [
    "69.195.159.158",
    "173.255.206.153",
  ]

  dhcp_netbios_name_servers = []
  dhcp_netbios_node_type    = 2

  #############################################################################
  ### IPv4 SUBNETS
  #############################################################################

  num_pub_subnets  = 0
  num_priv_subnets = 1
  priv_subnet_tags = [
    {
      Name = "Spoke-1-VPC-Private-Subnet-1"
    },
  ]
  ipv4_priv_newbits = 8
  ipv4_priv_netnum  = 128

  ### ROUTING AND INTERNET
  #############################################################################

  create_inet_gw = false
  num_nat_gws    = 0

  #############################################################################
  ### FLOWLOGS
  #############################################################################

  create_flow_log     = true
  flow_log_group_name = "Spoke-1-VPC-flowlog"

  #############################################################################
  ### ALL TAGS
  #############################################################################

  vpc_tags = {
    Name = "Spoke-1-VPC"
  }
}

## Spoke 2 VPC

module "spoke_2_vpc" {
  source = "git::ssh://git@github.com/IPyandy/terraform-aws-modules.git//vpc?ref=terraform-0.12"

  ### VPC
  create_vpc = true

  azs = [
    "us-east-1c",
    "us-east-1a",
    "us-east-1e",
  ]

  cidr_block                      = "10.246.0.0/16"
  instance_tenancy                = "default"
  enable_dns_hostnames            = true
  enable_dns_support              = true
  enable_classic_link             = false
  enable_classic_link_dns_support = false

  ### DHCP OPTIONS
  create_dhcp_options      = true
  dhcp_domain_name         = var.domain_name
  dhcp_domain_name_servers = ["AmazonProvidedDNS"]

  dhcp_ntp_servers = [
    "69.195.159.158",
    "173.255.206.153",
  ]

  dhcp_netbios_name_servers = []
  dhcp_netbios_node_type    = 2

  #############################################################################
  ### IPv4 SUBNETS
  #############################################################################

  num_pub_subnets  = 0
  num_priv_subnets = 1
  priv_subnet_tags = [
    {
      Name = "Spoke-2-VPC-Private-Subnet-1"
    },
  ]
  ipv4_priv_newbits = 8
  ipv4_priv_netnum  = 128

  ### ROUTING AND INTERNET
  #############################################################################

  create_inet_gw = false
  num_nat_gws    = 0

  #############################################################################
  ### FLOWLOGS
  #############################################################################

  create_flow_log     = true
  flow_log_group_name = "Spoke-2-VPC-flowlog"

  #############################################################################
  ### ALL TAGS
  #############################################################################

  vpc_tags = {
    Name = "Spoke-2-VPC"
  }
}
