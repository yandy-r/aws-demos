resource "aws_security_group" "central_public" {
  description = "Central instances Public SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

  tags = {
    Name = "Central Public"
  }
}


resource "aws_security_group" "central_private" {
  description = "Central instances Private SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

  tags = {
    Name = "Central Private"
  }
}

resource "aws_security_group_rule" "central_rules" {
  for_each                 = local.central_rules
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
    description = "Allow all from Central"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/16"]
  }

  ingress {
    description = "Allow only ICMP from Spoke 2"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.242.0.0/16"]
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
    description = "Allow all from Central"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/16"]
  }

  ingress {
    description = "Allow only ICMP from Spoke 1"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.241.0.0/16"]
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
    description = "Allow all from Central"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/16"]
  }

  tags = {
    Name = "Spoke 3"
  }
}
