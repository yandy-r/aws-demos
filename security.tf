resource "aws_security_group" "this" {
  count       = length(local.vpc_ids)
  description = "Security group that allows inter-vpc communication"

  vpc_id = local.vpc_ids[count.index]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress" {
  count             = length(local.vpc_ids)
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = element(aws_security_group.this.*.id, count.index)
  cidr_blocks       = local.cidr_blocks
}

resource "aws_security_group_rule" "allow_home_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  security_group_id = element(aws_security_group.this.*.id, 0)
  cidr_blocks       = [var.home_ip]
}

resource "aws_security_group_rule" "allow_home_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "ICMP"
  security_group_id = element(aws_security_group.this.*.id, 0)
  cidr_blocks       = [var.home_ip]
}
