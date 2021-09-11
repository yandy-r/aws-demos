### -------------------------------------------------------------------------------------------- ###
### VERSIONS
### -------------------------------------------------------------------------------------------- ###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.56"
    }
  }
}

### -------------------------------------------------------------------------------------------- ###
### ROUTE53
### -------------------------------------------------------------------------------------------- ###

locals {
  zone_names            = { for k, v in aws_route53_zone.this : k => v.name }
  zone_ids              = { for k, v in aws_route53_zone.this : k => v.zone_id }
  zone_arns             = { for k, v in aws_route53_zone.this : k => v.arn }
  name_servers          = { for k, v in aws_route53_zone.this : k => v.name_servers }
  resolver_endpoint_ids = { for k, v in aws_route53_resolver_endpoint.this : k => v.id }
  security_group_ids    = { for k, v in aws_security_group.this : k => v.id }
}

resource "aws_route53_zone" "this" {
  for_each          = { for k, v in var.route53_zone : k => v }
  name              = each.value["name"]
  comment           = lookup(each.value, "comment", null)
  delegation_set_id = lookup(each.value, "delegation_set_id", null)
  force_destroy     = lookup(each.value, "force_destroy", null)

  dynamic "vpc" {
    for_each = { for k, v in lookup(each.value, "vpc", {}) : k => v }
    content {
      vpc_id     = vpc.value["vpc_id"]
      vpc_region = lookup(vpc.value, "vpc_region", null)
    }
  }

  lifecycle {
    ignore_changes = [vpc]
  }

  tags = merge(
    {
      Name = "${var.name}-${each.key}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route53_zone_association" "this" {
  for_each   = { for k, v in var.route53_zone_association : k => v }
  zone_id    = each.value["zone_id"]
  vpc_id     = each.value["vpc_id"]
  vpc_region = lookup(each.value, "vpc_region", null)
}

resource "aws_route53_record" "this" {
  for_each        = { for k, v in var.route53_record : k => v }
  zone_id         = each.value["zone_id"]
  name            = each.value["name"]
  type            = each.value["type"]
  ttl             = lookup(each.value, "ttl", null)
  allow_overwrite = lookup(each.value, "allow_overwrite", null)
  records         = [for k, v in lookup(each.value, "records", {}) : v]

  dynamic "alias" {
    for_each = { for k, v in lookup(each.value, "alias", {}) : k => v }
    content {
      name                   = alias.value["name"]
      zone_id                = alias.value["zone_id"]
      evaluate_target_health = lookup(alias.value, "evaluate_target_health", true)
    }
  }
}

# ### -------------------------------------------------------------------------------------------- ###
# ### SECURITY GROUPS
# ### -------------------------------------------------------------------------------------------- ###

resource "aws_security_group" "this" {
  for_each    = { for k, v in var.security_groups : k => v }
  description = lookup(each.value, "description", null)
  vpc_id      = each.value["vpc_id"]

  dynamic "egress" {
    for_each = { for k, v in lookup(each.value, "egress", {}) : k => v }
    content {
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      protocol         = egress.value["protocol"]
      self             = lookup(egress.value, "self", null)
      description      = lookup(egress.value, "description", null)
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      security_groups  = lookup(egress.value, "security_groups", null)
    }
  }

  dynamic "ingress" {
    for_each = { for k, v in lookup(each.value, "ingress", {}) : k => v }
    content {
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      protocol         = ingress.value["protocol"]
      self             = lookup(ingress.value, "self", null)
      description      = lookup(ingress.value, "description", null)
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_security_group_rule" "this" {
  for_each                 = { for k, v in var.security_group_rules : k => v }
  description              = lookup(each.value, "description", null)
  type                     = lookup(each.value, "type", null)
  from_port                = lookup(each.value, "from_port", null)
  to_port                  = lookup(each.value, "to_port", null)
  protocol                 = lookup(each.value, "protocol", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  security_group_id        = lookup(each.value, "security_group_id", null)
}

# ### -------------------------------------------------------------------------------------------- ###
# ### RESOLVERS
# ### -------------------------------------------------------------------------------------------- ###

resource "aws_route53_resolver_endpoint" "this" {
  for_each           = { for k, v in var.route53_resolver_endpoint : k => v }
  name               = lookup(each.value, "name", null)
  direction          = lookup(each.value, "direction", "INBOUND")
  security_group_ids = each.value["security_group_ids"]

  dynamic "ip_address" {
    for_each = { for k, v in lookup(each.value, "ip_address", {}) : k => v }
    content {
      subnet_id = ip_address.value["subnet_id"]
      ip        = lookup(ip_address.value, "ip", null)
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}

resource "aws_route53_resolver_rule" "this" {
  for_each             = { for k, v in var.route53_resolver_rule : k => v }
  domain_name          = each.value["domain_name"]
  name                 = lookup(each.value, "name", null)
  rule_type            = lookup(each.value, "rule_type", "FORWARD")
  resolver_endpoint_id = lookup(each.value, "resolver_endpoint_id", null)

  dynamic "target_ip" {
    for_each = { for k, v in lookup(each.value, "target_ip", {}) : k => v }
    content {
      ip   = lookup(target_ip.value, "ip", null)
      port = lookup(target_ip.value, "port", 53)
    }
  }

  tags = merge(
    {
      Name = "${var.name}-${lookup(each.value, "name", "${each.key}")}"
    },
    var.tags,
    lookup(each.value, "tags", null)
  )
}
