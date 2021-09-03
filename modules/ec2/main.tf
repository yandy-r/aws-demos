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

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.priv_key.public_key_openssh
}

resource "aws_network_interface" "this" {
  for_each          = { for k, v in var.custom_eni_props : k => v if var.craate_custom_eni }
  subnet_id         = each.value["subnet_id"]
  security_groups   = lookup(each.value, "security_groups", null)
  private_ips       = lookup(each.value, "private_ips", null)
  source_dest_check = lookup(each.value, "source_dst_check", true)
  # attachment        = lookup(each.value, "attachment", null)

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

# resource "aws_instance" "hub_public" {
#   count            = 1
#   ami              = data.aws_ami.amzn2_linux.id
#   instance_type    = "t3.medium"
#   key_name         = aws_key_pair.aws_test_key.key_name
#   user_data_base64 = base64encode(data.template_file.cloud_config[count.index].rendered)

#   network_interface {
#     network_interface_id = aws_network_interface.hub.*.id[0]
#     device_index         = 0
#   }

#   tags = {
#     Name = "hub bastion"
#   }

#   depends_on = [aws_key_pair.aws_test_key]
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
