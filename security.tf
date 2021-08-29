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

locals {
  central_rules = {

    public_sg_egress = {
      description              = "Allow all outbound"
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_sg_rule1 = {
      description              = "Allow SSH from HOME/Office IP"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      cidr_blocks              = [var.self_public_ip]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_sg_rule2 = {
      description              = "Allow ICMP from HOME/Office IP"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      cidr_blocks              = [var.self_public_ip]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_sg_rule3 = {
      description              = "Allow SSH from Central Private subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.central_private.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_sg_rule4 = {
      description              = "Allow SSH from Central Public subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.central_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_sg_rule5 = {
      description              = "Allow ICMP from Central Private subnet"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      source_security_group_id = aws_security_group.central_private.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_public.id
    }

    private_egress = {
      description              = "Allow all outbound"
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule1 = {
      description              = "Allow all from Spoke VPC 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.241.0.0/16"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule2 = {
      description              = "Allow all from Spoke VPC 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.242.0.0/16"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule3 = {
      description              = "Allow all from Spoke VPC 3"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.243.0.0/16"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule4 = {
      description              = "Allow SSH from Central Public subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.central_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule5 = {
      description              = "Allow ICMP from Central Public subnet"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      source_security_group_id = aws_security_group.central_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_private.id
    }
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
