#!/bin/bash

set -e

USAGE="elbs-delete.sh [environment] [service]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

DESCRIBE_ELBS=$(aws elb describe-load-balancers --output text --load-balancer-names $ENVIRONMENT-$SERVICE)

if [ "$DESCRIBE_ELBS" = "" ]; then
  echo -e "aws_Status:\tnomatch"
  exit 0
fi

ELB_NAMES=$(echo "$DESCRIBE_ELBS" | grep "^LOADBALANCER" | cut -f6)

echo -e "You are about to terminate these elbs:\n\n$ELB_NAMES"
echo -en "\nAre you sure? [N|y]: "

read CONTINUE && [ "$CONTINUE" = "y" ] || exit 0

ELB_IDS=$ELB_NAMES

$(echo "$ELB_IDS" | xargs aws elb delete-load-balancer --load-balancer-name) 

echo -e "aws_Status:\tsuccess"

exit 0

