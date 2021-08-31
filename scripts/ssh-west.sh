#!/bin/bash

WEST_BASTION="$(jq -r '.resources[] |
select(.name == "hub_public") |
select(.type == "aws_instance") |
select(.module == "module.tgw_west") |
.instances[0].attributes.public_ip' <terraform.tfstate)"

ssh -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-west-2-test-key \
  ec2-user@"${WEST_BASTION}"
