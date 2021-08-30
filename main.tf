module "tgw" {
  source              = "./transit-gw"
  self_public_ip      = var.self_public_ip
  priv_ssh_key_path   = var.priv_ssh_key_path
  hostnames           = var.hostnames
  domain_name         = var.domain_name
  create_flow_logs    = var.create_flow_logs
  create_vpc_endpoint = var.create_vpc_endpoint
}
