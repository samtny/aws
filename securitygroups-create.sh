#!/bin/bash

USAGE="Usage: securitygroups-create.sh [securitygroup-name] [vpc-id]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

SECURITY_GROUP_NAME=$1
VPC_ID=$2

SLEEP_RESOURCE_CREATE=1

SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description $SECURITY_GROUP_NAME --vpc-id $VPC_ID | grep GroupId | cut -d':' -f2 | cut -d'"' -f2)

RETVAL=-1
while [ $RETVAL -ne 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID || true)
  RETVAL=$?
done

aws ec2 create-tags --tags Key=Name,Value=$SECURITY_GROUP_NAME --resources $SECURITY_GROUP_ID >/dev/null

echo -e "aws_SecurityGroupId:\t$SECURITY_GROUP_ID"

exit 0

