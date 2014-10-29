#!/bin/bash

set -e

USAGE="Usage: ips-get.sh [environment] [service] [subnet-ids]"

if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
SUBNET_IDS=$3

FILTERS="Name=tag:Environment,Values=$ENVIRONMENT"
[ "$SERVICE" != "" ] && FILTERS="$FILTERS Name=tag:Name,Values=$ENVIRONMENT-$SERVICE"
[ "$SUBNET_IDS" != "" ] && FILTERS="$FILTERS Name=subnet-id,Values=$SUBNET_IDS"

DESCRIBE_INSTANCES=$(aws ec2 describe-instances --output text --filters $FILTERS)

NETWORKINTERFACES=$(echo "$DESCRIBE_INSTANCES" | grep "^NETWORKINTERFACES")

if [ "$NETWORKINTERFACES" != "" ]; then
  IP_ADDRESSES=$(echo "$NETWORKINTERFACES" | cut -f5 | uniq)
fi

echo "$IP_ADDRESSES"

exit 0

