### -------------------------------------------------------------------------------------------- ###
### PROVIDERS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.56"
    }
  }
}

locals {
  network_interface_ids = { for k, v in aws_network_interface.this : k => v.id }
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.priv_key.public_key_openssh
}

resource "aws_network_interface" "this" {
  for_each           = var.network_interfaces
  subnet_id          = each.value["subnet_id"]
  description        = lookup(each.value, "description", null)
  private_ips        = lookup(each.value, "private_ips", null)
  private_ips_count  = lookup(each.value, "private_ips_count", null)
  ipv6_addresses     = lookup(each.value, "ipv6_addresses", null)
  ipv6_address_count = lookup(each.value, "ipv6_address_count", null)
  source_dest_check  = lookup(each.value, "source_dest_check", true)
  security_groups    = lookup(each.value, "security_groups", null)
  interface_type     = lookup(each.value, "interface_type", null)

  dynamic "attachment" {
    for_each = lookup(each.value, "attachment", {})
    content {
      instance     = attachment.value["instance"]
      device_index = attachment.value["device_index"]
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_instance" "this" {
  for_each         = var.aws_instances
  ami              = each.value["ami"]
  instance_type    = lookup(each.value, "instance_type", "t3.micro")
  key_name         = aws_key_pair.this.key_name
  user_data_base64 = lookup(each.value, "user_data", null)

  dynamic "network_interface" {
    for_each = lookup(each.value, "network_interface", {})
    content {
      network_interface_id = lookup(network_interface.value, "network_interface_id", element(concat([aws_network_interface.this[each.key].id], [""]), 0))
      device_index         = lookup(network_interface.value, "device_index", 0)
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )

  depends_on = [aws_key_pair.this]
}

# }

# resource "aws_network_interface" "private" {
#   count             = 4
#   subnet_id         = aws_subnet.private[count.index].id
#   private_ips       = [cidrhost(aws_subnet.private[count.index].cidr_block, 10)]
#   source_dest_check = true

#   security_groups = [
#     [
#       aws_security_group.hub_private.id,
#       aws_security_group.spoke_1.id,
#       aws_security_group.spoke_2.id,
#       aws_security_group.spoke_3.id
#   ][count.index]]

#   tags = element([
#     {
#       Name = "hub private"
#     },
#     {
#       Name = "spoke 1"
#     },
#     {
#       Name = "spoke 2"
#     },
#     {
#       Name = "spoke 3"
#     }
#   ], count.index)
# }

# ## spoke VPC Instances

# resource "aws_instance" "private" {
#   count            = 4
#   ami              = data.aws_ami.amzn2_linux.id
#   instance_type    = "t3.medium"
#   key_name         = aws_key_pair.aws_test_key.key_name
#   user_data_base64 = base64encode(data.template_file.cloud_config[count.index + 1].rendered)

#   network_interface {
#     network_interface_id = aws_network_interface.private[count.index].id
#     device_index         = 0
#   }

#   tags = element([
#     {
#       Name = "hub private"
#     },
#     {
#       Name = "spoke 1"
#     },
#     {
#       Name = "spoke 2"
#     },
#     {
#       Name = "spoke 3"
#     }
#   ], count.index)

#   depends_on = [aws_key_pair.aws_test_key]
# }
