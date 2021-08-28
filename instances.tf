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

## Network Interfaces

resource "aws_network_interface" "core" {
  count             = 1
  subnet_id         = aws_subnet.public.*.id[0]
  security_groups   = [aws_security_group.core_private_sg.id, aws_security_group.core_public_sg.id]
  private_ips       = [cidrhost(element(aws_subnet.public.*.cidr_block, count.index), 10)]
  source_dest_check = true

  tags = {
    Name = "core-1a-eni"
  }
}

## Core VPC Instances

resource "aws_instance" "core_instance" {
  ami              = data.aws_ami.amzn2_linux.id
  instance_type    = "t2.micro"
  key_name         = aws_key_pair.aws_test_key.key_name
  user_data_base64 = base64encode(data.template_file.cloud_config[0].rendered)

  network_interface {
    network_interface_id = aws_network_interface.core.*.id[0]
    device_index         = 0
  }

  tags = {
    Name = "Core Bastion"
  }
}

output "ec2_core_private_ips" {
  value = aws_instance.core_instance.private_ip
}

output "ec2_core_public_ips" {
  value = aws_instance.core_instance.public_ip

}

resource "aws_network_interface" "spokes" {
  count             = 3
  subnet_id         = element(aws_subnet.private.*.id, count.index + 1)
  security_groups   = [element([aws_security_group.spoke_1_private_sg.id, aws_security_group.spoke_2_private_sg.id, aws_security_group.spoke_3_private_sg.id], count.index)]
  private_ips       = [cidrhost(element(aws_subnet.private.*.cidr_block, count.index + 1), 10)]
  source_dest_check = true

  tags = element([
    {
      Name = "spoke-1-eni"
    },
    {
      Name = "spoke-2-eni"
    },
    {
      Name = "spoke-3-eni"
    }
  ], count.index)
}

## Spoke VPC Instances

resource "aws_instance" "spoke_instances" {
  count            = 3
  ami              = data.aws_ami.amzn2_linux.id
  instance_type    = "t2.micro"
  key_name         = aws_key_pair.aws_test_key.key_name
  user_data_base64 = base64encode(data.template_file.cloud_config[count.index + 1].rendered)

  network_interface {
    network_interface_id = aws_network_interface.spokes[count.index].id
    device_index         = 0
  }

  tags = element([
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

output "ec2_spoke_private_ips" {
  value = {
    for i in aws_instance.spoke_instances :
    i.id => i.private_ip
  }
}
