#!/bin/bash

set -e

USAGE="lcs-delete.sh [environment] [service]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

DESCRIBE_LCS=$(aws autoscaling describe-launch-configurations --output text --launch-configuration-name $ENVIRONMENT-$SERVICE)

if [ "$DESCRIBE_LCS" = "" ]; then
  echo -e "aws_Status:\tnomatch"
  exit 0
fi

LC_NAMES=$(echo "$DESCRIBE_LCS" | grep "^LAUNCHCONFIGURATIONS" | cut -f9)

echo -e "You are about to terminate these lcs:\n\n$LC_NAMES"
echo -en "\nAre you sure? [N|y]: "

read CONTINUE && [ "$CONTINUE" = "y" ] || exit 0

LC_IDS=$LC_NAMES

$(echo "$LC_IDS" | xargs aws autoscaling delete-launch-configuration --launch-configuration-name) 

echo -e "aws_Status:\tsuccess"

exit 0

