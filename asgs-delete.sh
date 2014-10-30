#!/bin/bash

set -e

USAGE="asgs-delete.sh [environment] [service]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

DESCRIBE_ASGS=$(aws autoscaling describe-auto-scaling-groups --output text --auto-scaling-group-names $ENVIRONMENT-$SERVICE)

if [ "$DESCRIBE_ASGS" = "" ]; then
  echo -e "aws_Status:\tnomatch"
  exit 0
fi

ASG_NAMES=$(echo "$DESCRIBE_ASGS" | grep "TAGS$(echo -e \\t)Name" | cut -f4)

echo -e "You are about to terminate these asgs:\n\n$ASG_NAMES"
echo -en "\nAre you sure? [N|y]: "

read CONTINUE && [ "$CONTINUE" = "y" ] || exit 0

ASG_IDS=$ASG_NAMES

$(echo "$ASG_IDS" | xargs aws autoscaling delete-auto-scaling-group --force-delete --auto-scaling-group-name) 

echo -e "aws_Status:\tsuccess"

exit 0

