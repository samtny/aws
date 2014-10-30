#!/bin/bash

set -e

USAGE="Usage: subnets-create.sh [subnet-name] [vpc-id] [cidr-block] [availability-zone]"

if [ $# -ne 4 ]; then
  echo "$USAGE"
  exit 1
fi

SUBNET_NAME=$1
VPC_ID=$2
CIDR_BLOCK=$3
AVAILABILITY_ZONE=$4

SLEEP_RESOURCE_CREATE=2

SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $CIDR_BLOCK --availability-zone $AVAILABILITY_ZONE | grep SubnetId | cut -d':' -f2 | cut -d'"' -f2)

RETVAL=-1
while [ $RETVAL -ne 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws ec2 describe-subnets --subnet-ids $SUBNET_ID || true)
  RETVAL=$?
done

aws ec2 create-tags --tags Key=Name,Value=$SUBNET_NAME --resources $SUBNET_ID >/dev/null 

echo -e "aws_SubnetId:\t$SUBNET_ID"

exit 0

