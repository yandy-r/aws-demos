### -------------------------------------------------------------------------------------------- ###
### PROVIDERS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

### -------------------------------------------------------------------------------------------- ###
### VPCS
### -------------------------------------------------------------------------------------------- ###

data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  azs = data.aws_availability_zones.azs
}

resource "aws_vpc" "vpcs" {
  count                = length(var.vpc_cidr_blocks)
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  cidr_block           = var.vpc_cidr_blocks[count.index]

  tags = element([
    {
      Name = "Hub VPC"
    },
    {
      Name = "Spoke VPC 1"
    },
    {
      Name = "Spoke VPC 2"
    },
    {
      Name = "Spoke VPC 3"
    },
  ], count.index)
}

resource "aws_internet_gateway" "inet_gw" {
  vpc_id = aws_vpc.vpcs[0].id

  tags = {
    Name = "Hub InetGW"
  }
}

resource "aws_eip" "nat_gw" {
  vpc = true

  tags = {
    Name = "Hub NatGw"
  }

  depends_on = [aws_internet_gateway.inet_gw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.inet_gw]
}

resource "aws_subnet" "public" {
  count                   = 1
  vpc_id                  = element(aws_vpc.vpcs.*.id, count.index)
  cidr_block              = cidrsubnet(aws_vpc.vpcs[0].cidr_block, 8, 0)
  availability_zone       = local.azs.names[0]
  map_public_ip_on_launch = "true"

  tags = element([
    {
      Name = "Hub VPC Public Subnet"
    }
  ], count.index)
}

resource "aws_subnet" "private" {
  count                   = 4
  vpc_id                  = aws_vpc.vpcs[count.index].id
  cidr_block              = cidrsubnet(aws_vpc.vpcs[count.index].cidr_block, 8, 128)
  availability_zone       = local.azs.names[count.index]
  map_public_ip_on_launch = "false"

  tags = element([
    {
      Name = "Hub VPC Private Subnet"
    },
    {
      Name = "Spoke VPC 1 Private Subnet"
    },
    {
      Name = "Spoke VPC 2 Private Subnet"
    },
    {
      Name = "Spoke VPC 3 Private Subnet"
    },
  ], count.index)
}

resource "aws_route_table" "public" {
  count  = 1
  vpc_id = element(aws_vpc.vpcs.*.id, count.index)

  tags = element([
    {
      Name = "Hub Public RT"
    }
  ], count.index)
}

resource "aws_route_table" "private" {
  count  = 4
  vpc_id = element(aws_vpc.vpcs.*.id, count.index)

  tags = element([
    {
      Name = "Hub Private RT"
    },
    {
      Name = "Spoke 1 Private RT"
    },
    {
      Name = "Spoke 2 Private RT"
    },
    {
      Name = "Spoke 3 Private RT"
    },
  ], count.index)
}

resource "aws_route_table_association" "public" {
  count          = length(aws_route_table.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_route_table.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "hub_inet_gw_default" {
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

resource "aws_route" "hub_nat_gw_default" {
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route" "hub_to_spokes_private" {
  count                  = 3
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

resource "aws_route" "hub_to_spokes_public" {
  count                  = 3
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = aws_vpc.vpcs[count.index + 1].cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

resource "aws_route" "tgw_spoke_defaults" {
  count                  = 3
  route_table_id         = aws_route_table.private[count.index + 1].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.attach]
}

### FLOW LOGS

resource "aws_iam_role" "flow_logs" {
  count              = var.create_flow_logs ? 1 : 0
  name               = "flow_logs"
  assume_role_policy = file("${path.module}/templates/flow_logs_role.json")

  tags = {
    Name = "Flow Logs"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count  = var.create_flow_logs ? 1 : 0
  name   = "flow_logs"
  role   = aws_iam_role.flow_logs[0].id
  policy = file("${path.module}/templates/flow_logs_role_policy.json")
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.create_flow_logs ? 1 : 0
  name  = "flow_logs"

  tags = {
    Name = "Flow logs"
  }
}

resource "aws_flow_log" "flow_logs" {
  count           = var.create_flow_logs ? length(aws_vpc.vpcs) : 0
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpcs[count.index].id
}

data "template_file" "s3_endpoint_policy" {
  template = file("${path.module}/templates/s3_endpoint_policy.json")

  vars = {
    bucket_arn = aws_s3_bucket.lab_data.arn
  }
}
resource "aws_vpc_endpoint" "s3" {
  count             = var.create_vpc_endpoint ? 1 : 0
  vpc_id            = aws_vpc.vpcs[0].id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.us-east-1.s3"
  policy            = data.template_file.s3_endpoint_policy.rendered

  tags = {
    Name = "S3 Endpoint"
  }
}

locals {
  hub_rts = [
    aws_route_table.public[0], aws_route_table.private[0]
  ]
}
resource "aws_vpc_endpoint_route_table_association" "s3" {
  for_each        = { for k, v in local.hub_rts : k => v.id }
  route_table_id  = each.value
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

### -------------------------------------------------------------------------------------------- ###
### EC2 INSTANCES
### -------------------------------------------------------------------------------------------- ###

resource "tls_private_key" "aws_test_priv_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "aws_test_key" {
  key_name   = "aws-test-key"
  public_key = tls_private_key.aws_test_priv_key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.aws_test_priv_key.private_key_pem}' > ~/.aws-keys/'${aws_key_pair.aws_test_key.key_name}'"
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.aws_test_priv_key.public_key_openssh}' > ~/.aws-keys/'${aws_key_pair.aws_test_key.key_name}'.pub"
  }

  provisioner "local-exec" {
    command = "chmod 600 ~/.aws-keys/'${aws_key_pair.aws_test_key.key_name}'"
  }
  provisioner "local-exec" {
    command = "chmod 600 ~/.aws-keys/'${aws_key_pair.aws_test_key.key_name}'.pub"
  }
}

data "aws_ami" "amzn2_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-hirsute-21.04-amd64-server*"]
  }
}

data "template_file" "cloud_config" {
  count    = length(var.hostnames)
  template = file("${path.module}/templates/cloud-config.tpl")

  vars = {
    hostname = var.hostnames[count.index]
    ssh_key  = data.local_file.ssh_key.content
  }
}

data "local_file" "ssh_key" {
  filename = pathexpand(var.priv_ssh_key_path)

  depends_on = [
    aws_key_pair.aws_test_key
  ]
}

resource "aws_network_interface" "hub" {
  count             = 1
  subnet_id         = aws_subnet.public[0].id
  security_groups   = [aws_security_group.hub_public.id]
  private_ips       = [cidrhost(aws_subnet.public[count.index].cidr_block, 10)]
  source_dest_check = true

  tags = {
    Name = "Hub Public"
  }
}

resource "aws_instance" "hub_public" {
  count            = 1
  ami              = data.aws_ami.amzn2_linux.id
  instance_type    = "t2.micro"
  key_name         = aws_key_pair.aws_test_key.key_name
  user_data_base64 = base64encode(data.template_file.cloud_config[count.index].rendered)

  network_interface {
    network_interface_id = aws_network_interface.hub.*.id[0]
    device_index         = 0
  }

  tags = {
    Name = "Hub Bastion"
  }

  depends_on = [aws_key_pair.aws_test_key]
}

resource "aws_network_interface" "private" {
  count             = 4
  subnet_id         = aws_subnet.private[count.index].id
  private_ips       = [cidrhost(aws_subnet.private[count.index].cidr_block, 10)]
  source_dest_check = true

  security_groups = [
    [
      aws_security_group.hub_private.id,
      aws_security_group.spoke_1.id,
      aws_security_group.spoke_2.id,
      aws_security_group.spoke_3.id
  ][count.index]]

  tags = element([
    {
      Name = "Hub Private"
    },
    {
      Name = "Spoke 1"
    },
    {
      Name = "Spoke 2"
    },
    {
      Name = "Spoke 3"
    }
  ], count.index)
}

## Spoke VPC Instances

resource "aws_instance" "private" {
  count            = 4
  ami              = data.aws_ami.amzn2_linux.id
  instance_type    = "t2.micro"
  key_name         = aws_key_pair.aws_test_key.key_name
  user_data_base64 = base64encode(data.template_file.cloud_config[count.index + 1].rendered)

  network_interface {
    network_interface_id = aws_network_interface.private[count.index].id
    device_index         = 0
  }

  tags = element([
    {
      Name = "Hub Private"
    },
    {
      Name = "Spoke 1"
    },
    {
      Name = "Spoke 2"
    },
    {
      Name = "Spoke 3"
    }
  ], count.index)

  depends_on = [aws_key_pair.aws_test_key]
}

### -------------------------------------------------------------------------------------------- ###
### SECURITY GROUPS
### -------------------------------------------------------------------------------------------- ###

resource "aws_security_group" "hub_public" {
  description = "Hub instances Public SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

  tags = {
    Name = "Hub Public"
  }
}


resource "aws_security_group" "hub_private" {
  description = "Hub instances Private SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

  tags = {
    Name = "Hub Private"
  }
}

locals {
  hub_rules = {

    public_egress = {
      description              = "Allow all outbound"
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_public.id
    }

    public_rule_1 = {
      description              = "Allow SSH from HOME/Office IP"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      cidr_blocks              = [var.self_public_ip]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_public.id
    }

    public_rule_2 = {
      description              = "Allow ICMP from HOME/Office IP"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      cidr_blocks              = [var.self_public_ip]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_public.id
    }

    public_rule_3 = {
      description              = "Allow SSH from Hub Private subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.hub_private.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.hub_public.id
    }

    public_rule_4 = {
      description              = "Allow SSH from Hub Public subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.hub_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.hub_public.id
    }

    public_rule_5 = {
      description              = "Allow ICMP from Hub Private subnet"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      source_security_group_id = aws_security_group.hub_private.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.hub_public.id
    }

    private_egress = {
      description              = "Allow all outbound"
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_private.id
    }

    private_rule_1 = {
      description              = "Allow all from Spoke VPC 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = [aws_vpc.vpcs[1].cidr_block]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_private.id
    }

    private_rule_2 = {
      description              = "Allow all from Spoke VPC 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = [aws_vpc.vpcs[2].cidr_block]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_private.id
    }

    private_rule_3 = {
      description              = "Allow all from Spoke VPC 3"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = [aws_vpc.vpcs[3].cidr_block]
      source_security_group_id = null
      security_group_id        = aws_security_group.hub_private.id
    }

    private_rule_4 = {
      description              = "Allow SSH from Hub Public subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.hub_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.hub_private.id
    }

    private_rule_5 = {
      description              = "Allow ICMP from Hub Public subnet"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      source_security_group_id = aws_security_group.hub_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.hub_private.id
    }
  }
}

resource "aws_security_group_rule" "hub_rules" {
  for_each                 = local.hub_rules
  description              = each.value.description
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = each.value.security_group_id
}

resource "aws_security_group" "spoke_1" {
  description = "Spoke 1 Private"
  vpc_id      = aws_vpc.vpcs.*.id[1]

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Hub"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpcs[0].cidr_block]
  }

  ingress {
    description = "Allow only ICMP from Spoke 2"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.vpcs[2].cidr_block]
  }

  tags = {
    Name = "Spoke 1"
  }
}

resource "aws_security_group" "spoke_2" {
  description = "Spoke 2 Private"
  vpc_id      = aws_vpc.vpcs.*.id[2]

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Hub"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpcs[0].cidr_block]
  }

  ingress {
    description = "Allow only ICMP from Spoke 1"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.vpcs[1].cidr_block]
  }

  tags = {
    Name = "Spoke 2"
  }
}

resource "aws_security_group" "spoke_3" {
  description = "Spoke 3 Private"
  vpc_id      = aws_vpc.vpcs.*.id[3]

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Hub"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpcs[0].cidr_block]
  }

  tags = {
    Name = "Spoke 3"
  }
}

### -------------------------------------------------------------------------------------------- ###
### TRANSIT GATEWAY
### -------------------------------------------------------------------------------------------- ###

resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit Gateway Demo"
  amazon_side_asn                 = "64512"   # default
  auto_accept_shared_attachments  = "disable" # default
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable" # default
  vpn_ecmp_support                = "enable" # default

  tags = {
    Name = "TGW-${var.region}"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attach" {
  count                                           = length(aws_subnet.private)
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.vpcs[count.index].id
  subnet_ids                                      = [aws_subnet.private[count.index].id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = [
    {
      Name = "Hub VPC"
    },
    {
      Name = "Spoke 1 VPC"
    },
    {
      Name = "Spoke 2 VPC"
    },
    {
      Name = "Spoke 3 VPC"
  }][count.index]
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  count              = 1
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = element([
    {
      Name = "Hub Route Table"
    }
  ], count.index)
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  count              = 1
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = element([
    {
      Name = "Spokes"
    }
  ], count.index)
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "spokes" {
  count                          = 3
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub" {
  count                          = 4
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub_to_spokes" {
  count                          = 1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_1_to_2" {
  count                          = 2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[count.index + 1].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
}

resource "aws_ec2_transit_gateway_route" "spoke_defaults" {
  count                          = 1
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[count.index].id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.attach[0].id
}

resource "aws_ec2_transit_gateway_route" "black_hole" {
  count                          = 3
  destination_cidr_block         = var.rfc1918[count.index]
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes[0].id
  blackhole                      = "true"
}

### -------------------------------------------------------------------------------------------- ###
### S3
### -------------------------------------------------------------------------------------------- ###

resource "aws_s3_bucket" "lab_data" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Name = "Lab Data"
  }
}
