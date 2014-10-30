#!/bin/bash

USAGE="Usage: asgs-create.sh [environment] [service] [subnet-id] [load-balancer-names]"

if [ "$#" -lt 3 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
SUBNET_ID=$3
LOAD_BALANCER_NAMES=$4

ASG_NAME="$ENVIRONMENT-$SERVICE"
LC_NAME=$ASG_NAME
MIN_SIZE=1
MAX_SIZE=1
DESIRED_CAPACITY=1
HEALTH_CHECK_TYPE="EC2"
HEALTH_CHECK_GRACE_PERIOD=120
TAGS="ResourceId=$ASG_NAME,ResourceType=auto-scaling-group,Key=Name,Value=$ENVIRONMENT-$SERVICE,PropagateAtLaunch=true ResourceId=$ASG_NAME,ResourceType=auto-scaling-group,Key=Environment,Value=$ENVIRONMENT,PropagateAtLaunch=true"

[ "$LOAD_BALANCER_NAMES" != "" ] && EXTRA_ARGS="--load-balancer-names $LOAD_BALANCER_NAMES"

aws autoscaling create-auto-scaling-group --auto-scaling-group-name $ASG_NAME --launch-configuration-name $LC_NAME --min-size $MIN_SIZE --max-size $MAX_SIZE --desired-capacity $DESIRED_CAPACITY --health-check-type $HEALTH_CHECK_TYPE --health-check-grace-period $HEALTH_CHECK_GRACE_PERIOD --vpc-zone-identifier $SUBNET_ID --tags $TAGS $EXTRA_ARGS >/dev/null

echo -e "aws_asgName$SERVICE:\t$ASG_NAME"

exit 0

