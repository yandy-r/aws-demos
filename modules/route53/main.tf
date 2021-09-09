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
  zone_names   = { for k, v in aws_route53_zone.this : k => v.name }
  zone_ids     = { for k, v in aws_route53_zone.this : k => v.zone_id }
  zone_arns    = { for k, v in aws_route53_zone.this : k => v.arn }
  name_servers = { for k, v in aws_route53_zone.this : k => v.name_servers }
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
