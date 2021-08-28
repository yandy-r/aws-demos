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
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = [var.self_public_ip]
  }

  tags = {
    Name = "Central VPC Public"
  }
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
    description = "Allow all from Private"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Name = "Central VPC Private"
  }
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
    description = "Allow all from Private"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Name = "Spoke 1 VPC"
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
    description = "Allow all from Private"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Name = "Spoke 2 VPC"
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
    description = "Allow all from Private"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = {
    Name = "Spoke 3 VPC"
  }
}
