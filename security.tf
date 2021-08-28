resource "aws_security_group" "core_public_sg" {
  description = "Core instances Public SG"
  vpc_id      = aws_vpc.vpcs.*.id[0]

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

  tags = {
    Name = "Core VPC Public"
  }
}

resource "aws_security_group" "core_private_sg" {
  description = "Core instances Private SG"
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
    Name = "Core VPC Private"
  }
}

resource "aws_security_group" "spoke_1_private_sg" {
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

resource "aws_security_group" "spoke_2_private_sg" {
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

resource "aws_security_group" "spoke_3_private_sg" {
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
