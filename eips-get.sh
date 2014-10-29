#!/bin/bash

set -e

USAGE="Usage: eips-get.sh [environment] [service]"

if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

FILTERS="Name=tag:Environment,Values=$ENVIRONMENT"
[ "$SERVICE" != "" ] && FILTERS="$FILTERS Name=tag:Name,Values=$ENVIRONMENT-$SERVICE"

DESCRIBE_INSTANCES=$(aws ec2 describe-instances --output text --filters $FILTERS)

ASSOCIATIONS=$(echo "$DESCRIBE_INSTANCES" | grep "^ASSOCIATION")

if [ "$ASSOCIATIONS" != "" ]; then
  EIPS=$(echo "$ASSOCIATIONS" | cut -f4 | uniq)
fi

echo "$EIPS"

exit 0

