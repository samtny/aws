#!/bin/bash

set -e

USAGE="addresses-release.sh [environment] [service]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

SLEEP_RESOURCE_RELEASE=5
SLEEP_RESOURCE_DISASSOCIATE=2

FILTERS="Name=tag:Environment,Values=$ENVIRONMENT"
[ "$SERVICE" != "" ] && FILTERS="$FILTERS Name=tag:Name,Values=$ENVIRONMENT-$SERVICE"

DESCRIBE_INSTANCES=$(aws ec2 describe-instances --output text --filters $FILTERS)

if [ "$DESCRIBE_INSTANCES" = "" ]; then
  echo -e "aws_Status:\tnomatch"
  exit 0
fi

INSTANCE_NAMES=$(echo "$DESCRIBE_INSTANCES" | grep "TAGS$(echo -e \\t)Name" | cut -f3)

echo -e "You are about to release addresses associated with these instances:\n\n$INSTANCE_NAMES"
echo -en "\nAre you sure? [N|y]: "

read CONTINUE && [ "$CONTINUE" = "y" ] || exit 0

INSTANCE_IDS=$(echo "$DESCRIBE_INSTANCES" | grep "^INSTANCES" | cut -f8)

DESCRIBE_ADDRESSES=$(aws ec2 describe-addresses --output text --filters Name=instance-id,Values=$INSTANCE_IDS)

if [ "$DESCRIBE_ADDRESSES" = "" ]; then
  echo -e "aws_Status:\tnomatch"
  exit 0
fi

ASSOCIATION_IDS=$(echo "$DESCRIBE_ADDRESSES" | grep "^ADDRESSES" | cut -f3)

(echo "$ASSOCIATION_IDS" | xargs aws ec2 disassociate-address --association-id)

while [ "$INSTANCE_IDS" != "" ]; do
  sleep $SLEEP_RESOURCE_DISASSOCIATE
  INSTANCE_IDS=$(aws ec2 describe-instances --output text --filters Name=association.allocation-id,Values=$ALLOCATION_IDS)
done

ALLOCATION_IDS=$(echo "$DESCRIBE_ADDRESSES" | grep "^ADDRESSES" | cut -f2)

(echo "$ALLOCATION_IDS" | xargs aws ec2 release-address --allocation-id)

while [ "$DESCRIBE_ADDRESSES" != "" ]; do
  sleep $SLEEP_RESOURCE_RELEASE
  DESCRIBE_ADDRESSES=$(aws ec2 describe-addresses --output text --filters Name=instance-id,Values=$INSTANCE_IDS)
done

echo -e "aws_Status:\tsuccess"

exit 0

