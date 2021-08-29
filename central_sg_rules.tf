locals {
  central_rules = {

    public_egress = {
      description              = "Allow all outbound"
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_rule_1 = {
      description              = "Allow SSH from HOME/Office IP"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      cidr_blocks              = [var.self_public_ip]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_rule_2 = {
      description              = "Allow ICMP from HOME/Office IP"
      type                     = "ingress"
      from_port                = -1
      to_port                  = -1
      protocol                 = "icmp"
      cidr_blocks              = [var.self_public_ip]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_rule_3 = {
      description              = "Allow SSH from Central Private subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.central_private.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_rule_4 = {
      description              = "Allow SSH from Central Public subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.central_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_public.id
    }

    public_rule_5 = {
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

    private_rule_1 = {
      description              = "Allow all from Spoke VPC 1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.241.0.0/16"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule_2 = {
      description              = "Allow all from Spoke VPC 2"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.242.0.0/16"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule_3 = {
      description              = "Allow all from Spoke VPC 3"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["10.243.0.0/16"]
      source_security_group_id = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule_4 = {
      description              = "Allow SSH from Central Public subnet"
      type                     = "ingress"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.central_public.id
      cidr_blocks              = null
      security_group_id        = aws_security_group.central_private.id
    }

    private_rule_5 = {
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
