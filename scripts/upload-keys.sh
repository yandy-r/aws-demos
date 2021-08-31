#!/bin/bash

# UPLOAD WEST KEY TO EAST HUB
scp -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-east-1-test-key \
  keys/aws-us-west-2-test-key \
  ec2-user@"$(jq -r '.resources[] |
select(.name == "hub_public") |
select(.type == "aws_instance") |
select(.module == "module.tgw_east") |
.instances[0].attributes.public_ip' <terraform.tfstate)":.ssh/west-key

# UPLOAD EAST KEY TO WEST HUB
scp -o "StrictHostKeyChecking no" \
  -o "UserKnownHostsFile /dev/null" \
  -i keys/aws-us-west-2-test-key \
  keys/aws-us-west-2-test-key \
  ec2-user@"$(jq -r '.resources[] |
select(.name == "hub_public") |
select(.type == "aws_instance") |
select(.module == "module.tgw_west") |
.instances[0].attributes.public_ip' <terraform.tfstate)":.ssh/east-key
