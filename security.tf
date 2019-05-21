resource "aws_security_group" "core_public_sg" {
  description = "Core VPC Public Subnet Security Groups - Based on Subnet count not instance"
  vpc_id      = local.core_vpc_ids[0]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ### Allow home from remote network to SSH and ICMP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.self_public_ip]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = [var.self_public_ip]
  }
}

resource "aws_security_group_rule" "core_public_to_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.core_public_sg.id
  security_group_id        = aws_security_group.core_public_sg.id
}

resource "aws_security_group_rule" "core_public_from_core_private" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.core_private_sg.id
  security_group_id        = aws_security_group.core_public_sg.id
}

resource "aws_security_group_rule" "core_public_from_spokes" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.245.0.0/16", "10.246.0.0/16"]
  security_group_id = aws_security_group.core_public_sg.id
}

resource "aws_security_group" "core_private_sg" {
  description = "Core VPC Private Subnet Security Groups - Based on Subnet count not instance"
  vpc_id      = local.core_vpc_ids[0]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "core_private_to_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.core_private_sg.id
  security_group_id        = aws_security_group.core_private_sg.id
}


resource "aws_security_group_rule" "core_private_from_public" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.core_public_sg.id
  security_group_id        = aws_security_group.core_private_sg.id
}

resource "aws_security_group_rule" "core_private_from_spokes" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.245.0.0/16", "10.246.0.0/16"]
  security_group_id = aws_security_group.core_private_sg.id
}

resource "aws_security_group" "spoke_1_private_sg" {
  description = "Spoke 1 VPC Security Groups - Based on Subnet count not instance"
  vpc_id      = local.spoke_vpc_ids[0]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "spoke_1_to_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.spoke_1_private_sg.id
  security_group_id        = aws_security_group.spoke_1_private_sg.id
}

resource "aws_security_group_rule" "spoke_1_from_core" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.244.0.0/16"]
  security_group_id = aws_security_group.spoke_1_private_sg.id
}

resource "aws_security_group_rule" "spoke_1_from_spoke_2" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.246.0.0/16"]
  security_group_id = aws_security_group.spoke_1_private_sg.id
}

resource "aws_security_group" "spoke_2_private_sg" {
  description = "Spoke 2 VPC Security Groups - Based on Subnet count not instance"
  vpc_id      = local.spoke_vpc_ids[1]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "spoke_2_to_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.spoke_2_private_sg.id
  security_group_id        = aws_security_group.spoke_2_private_sg.id
}

resource "aws_security_group_rule" "spoke_2_from_core" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.244.0.0/16"]
  security_group_id = aws_security_group.spoke_2_private_sg.id
}

resource "aws_security_group_rule" "spoke_2_from_spoke_1" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.245.0.0/16"]
  security_group_id = aws_security_group.spoke_2_private_sg.id
}
