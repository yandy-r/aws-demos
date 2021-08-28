resource "aws_security_group" "central_public" {
  description = "Central instances Public SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.self_public_ip]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = [var.self_public_ip]
  }

  tags = {
    Name = "Central VPC Public"
  }
}

resource "aws_security_group_rule" "ssh_from_private" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.central_private.id
  security_group_id        = aws_security_group.central_public.id
}

resource "aws_security_group_rule" "icmp_from_private" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "ICMP"
  source_security_group_id = aws_security_group.central_private.id
  security_group_id        = aws_security_group.central_public.id
}

resource "aws_security_group" "central_private" {
  description = "Central instances Private SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Spoke VPC 1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.241.0.0/16"]
  }

  ingress {
    description = "Allow all from Spoke VPC 2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.242.0.0/16"]
  }

  ingress {
    description = "Allow all from Spoke VPC 3"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.243.0.0/16"]
  }

  tags = {
    Name = "Central VPC Private"
  }
}


resource "aws_security_group_rule" "ssh_from_public" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.central_public.id
  security_group_id        = aws_security_group.central_private.id
}

resource "aws_security_group_rule" "icmp_from_public" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "ICMP"
  source_security_group_id = aws_security_group.central_public.id
  security_group_id        = aws_security_group.central_private.id
}


resource "aws_security_group" "spoke_1" {
  description = "Spoke 1 instances Private SG"
  vpc_id      = aws_vpc.vpcs.*.id[1]

  egress {
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
    protocol    = "ICMP"
    cidr_blocks = ["10.242.0.0/16"]
  }

  tags = {
    Name = "Spoke 1"
  }
}

resource "aws_security_group" "spoke_2" {
  description = "Spoke 2 instances Private SG"
  vpc_id      = aws_vpc.vpcs.*.id[2]

  egress {
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
    protocol    = "ICMP"
    cidr_blocks = ["10.241.0.0/16"]
  }

  tags = {
    Name = "Spoke 2"
  }
}

resource "aws_security_group" "spoke_3" {
  description = "Spoke 3 instances Private SG"
  vpc_id      = aws_vpc.vpcs.*.id[3]

  egress {
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
    Name = "Spoke 3 VPC"
  }
}
