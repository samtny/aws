#!/bin/bash

set -e

USAGE="Usage: routetables-create.sh [name] [vpc-id]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

NAME=$1
VPC_ID=$2

SLEEP_RESOURCE_CREATE=2

ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID | grep RouteTableId | cut -d':' -f2 | cut -d'"' -f2)

RETVAL=-1
while [ ! $RETVAL = 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_ID) || true
  RETVAL=$?
done

aws ec2 create-tags --tags Key=Name,Value=$NAME --resources $ROUTE_TABLE_ID >/dev/null 

echo -e "aws_RouteTableId:\t$ROUTE_TABLE_ID"

exit 0

