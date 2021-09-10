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
  instance_private_dns  = { for k, v in aws_instance.this : k => v.private_dns }
  instance_private_ips  = { for k, v in aws_instance.this : k => v.private_ip }
}

resource "aws_key_pair" "this" {
  for_each        = { for k, v in var.ssh_key : k => v }
  key_name        = lookup(each.value, "key_name", null)
  key_name_prefix = lookup(each.value, "key_name_prefix", null)
  public_key      = each.value["public_key"]

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
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
  key_name         = lookup(each.value, "key_name", null)
  user_data        = lookup(each.value, "user_data", null)
  user_data_base64 = lookup(each.value, "user_data_base64", null)

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
