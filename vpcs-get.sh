#!/bin/bash

USAGE="Usage: vpcs-get.sh [environment]"

if [ $# -ne 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1

DESCRIBE_VPCS=$(aws ec2 describe-vpcs --output text --filters Name=tag:Name,Values=$ENVIRONMENT)

VPC_ID=$(echo "$DESCRIBE_VPCS" | grep "^VPCS" | cut -f7)

echo -e "aws_VpcId:\t$VPC_ID"

exit 0

