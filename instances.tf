## Network Interfaces

resource "aws_network_interface" "core" {
  count             = length(local.core_subnet_ids)
  subnet_id         = local.core_subnet_ids[count.index]
  security_groups   = [local.core_sg_ids[count.index]]
  private_ips       = [element(["10.244.0.10", "10.244.128.10"], count.index)]
  source_dest_check = true
  tags = element([
    {
      Name = "ec2-1a-eni"
    },
    {
      Name = "ec2-1b-eni"
    },
  ], count.index)
}

resource "aws_network_interface" "spokes" {
  count             = length(local.spoke_subnet_ids)
  subnet_id         = local.spoke_subnet_ids[count.index]
  security_groups   = [local.spoke_sg_ids[count.index]]
  private_ips       = [element(["10.245.128.10", "10.246.128.10"], count.index)]
  source_dest_check = true
  tags = element([
    {
      Name = "ec2-2-eni"
    },
    {
      Name = "ec2-3-eni"
    }
  ], count.index)
}

## Core VPC Instances

resource "aws_instance" "core_instances" {
  count            = 2
  ami              = data.aws_ami.amzn2_linux.id
  instance_type    = "t2.micro"
  key_name         = var.ssh_key_name
  user_data_base64 = base64encode(data.template_file.cloud_config[count.index].rendered)

  network_interface {
    network_interface_id = aws_network_interface.core[count.index].id
    device_index         = 0
  }

  tags = element([
    {
      Name = "ec2-1a-ssh-bastion"
    },
    {
      Name = "ec2-1b"
    },
  ], count.index)
}

output "ec2_core_private_ips" {
  value = {
    for i in aws_instance.core_instances :
    i.id => i.private_ip
  }
}

output "ec2_core_public_ips" {
  value = {
    for i in aws_instance.core_instances :
    i.id => i.public_ip
    if i.associate_public_ip_address
  }
}

## Spoke VPC Instances

resource "aws_instance" "spoke_instances" {
  count            = 2
  ami              = data.aws_ami.amzn2_linux.id
  instance_type    = "t2.micro"
  key_name         = var.ssh_key_name
  user_data_base64 = base64encode(data.template_file.cloud_config[count.index + 2].rendered)

  network_interface {
    network_interface_id = aws_network_interface.spokes[count.index].id
    device_index         = 0
  }

  tags = element([
    {
      Name = "ec2-2"
    },
    {
      Name = "ec2-3"
    },
  ], count.index)
}

output "ec2_spoke_private_ips" {
  value = {
    for i in aws_instance.spoke_instances :
    i.id => i.private_ip
  }
}
