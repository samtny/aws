#!/bin/bash

set -e

USAGE="instances-terminate.sh [environment] [service]"

if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

SLEEP_RESOURCE_DELETE=4

FILTERS="Name=tag:Environment,Values=$ENVIRONMENT"
FILTERS="$FILTERS Name=instance-state-name,Values=running,pending,shutting-down,stopping,stopped"
[ "$SERVICE" != "" ] && FILTERS="$FILTERS Name=tag:Name,Values=$ENVIRONMENT-$SERVICE"

DESCRIBE_INSTANCES=$(aws ec2 describe-instances --output text --filters $FILTERS)

if [ "$DESCRIBE_INSTANCES" = "" ]; then
  echo "No instances match.  Exiting."
  exit 0
fi

INSTANCE_NAMES=$(echo "$DESCRIBE_INSTANCES" | grep "TAGS$(echo -e \\t)Name" | cut -f3)

echo -e "You are about to terminate these instances:\n\n$INSTANCE_NAMES"
echo -en "\nAre you sure? [N|y]: "

read CONTINUE && [ "$CONTINUE" = "y" ] || exit 0

INSTANCE_IDS=$(echo "$DESCRIBE_INSTANCES" | grep "^INSTANCES" | cut -f8)

aws ec2 terminate-instances --instance-ids $(echo $INSTANCE_IDS | tr '\n' ' ')

while [ "$DESCRIBE_INSTANCES" != "" ]; do
  sleep $SLEEP_RESOURCE_DELETE
  DESCRIBE_INSTANCES=$(aws ec2 describe-instances --output text --filters $FILTERS)  
done

echo -e "aws_Status:\tsuccess"

exit 0

