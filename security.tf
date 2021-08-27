resource "aws_security_group" "core_public_sg" {
  description = "Core instances Public SG"
  vpc_id      = module.core_vpc.vpc_id

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
  vpc_id      = module.core_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from spokes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.241.0.0/16", "10.242.0.0/16", "10.243.0.0/16"]
  }

  tags = {
    Name = "Core VPC Private"
  }
}

resource "aws_security_group" "spoke_1_private_sg" {
  description = "Spoke 2 instances Private SG"
  vpc_id      = module.spoke_1_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Core"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/16"]
  }
  ingress {
    description = "Allow all from Spoke 2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.242.0.0/16"]
  }

  tags = {
    Name = "Spoke 1 VPC"
  }
}

resource "aws_security_group" "spoke_2_private_sg" {
  description = "Spoke 2 instances Private SG"
  vpc_id      = module.spoke_2_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Core"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/16"]
  }
  ingress {
    description = "Allow all from Spoke 1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.241.0.0/16"]
  }

  tags = {
    Name = "Spoke 2 VPC"
  }
}

resource "aws_security_group" "spoke_3_private_sg" {
  description = "Spoke 3 instances Private SG"
  vpc_id      = module.spoke_3_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from Core"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.240.0.0/16"]
  }

  tags = {
    Name = "Spoke 3 VPC"
  }
}
