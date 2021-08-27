## Network Interfaces

resource "aws_network_interface" "core" {
  count             = length(local.core_subnet_ids)
  subnet_id         = local.core_subnet_ids[count.index]
  security_groups   = [local.core_sg_ids[count.index]]
  private_ips       = [element(["10.240.0.10", "10.240.128.10"], count.index)]
  source_dest_check = true
  tags = element([
    {
      Name = "core-1a-eni"
    },
    {
      Name = "core-1b-eni"
    },
  ], count.index)
}

resource "aws_network_interface" "spokes" {
  count             = length(local.spoke_subnet_ids)
  subnet_id         = local.spoke_subnet_ids[count.index]
  security_groups   = [local.spoke_sg_ids[count.index]]
  private_ips       = [element(["10.241.128.10", "10.242.128.10", "10.243.128.10"], count.index)]
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
      Name = "core-1a-ssh-bastion"
    },
    {
      Name = "core-1b"
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
  count            = 3
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
      Name = "spoke-1"
    },
    {
      Name = "spoke-2"
    },
    {
      Name = "spoke-3"
    }
  ], count.index)
}

output "ec2_spoke_private_ips" {
  value = {
    for i in aws_instance.spoke_instances :
    i.id => i.private_ip
  }
}
