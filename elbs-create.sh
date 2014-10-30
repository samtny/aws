#!/bin/bash

set -e

USAGE="Usage: elbs-create.sh [environment] [service] [subnet-ids] [security-group-ids]"

if [ "$#" -ne 4 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
SUBNET_IDS=$3
SECURITY_GROUP_IDS=$4

ELB_NAME="$ENVIRONMENT-$SERVICE"
SSL_CERTIFICATE_ID=""

HTTP_LISTENER="Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=9000"
HTTPS_LISTENER="Protocol=HTTPS,LoadBalancerPort=443,InstanceProtocol=HTTP,InstancePort=9000"
LISTENERS=$(echo $HTTP_LISTENER)

TAGS="'Key=Environment,Value=$ENVIRONMENT'"

HEALTH_CHECK="Target=TCP:9000,Timeout=5,Interval=10,UnhealthyThreshold=2,HealthyThreshold=2"

aws elb create-load-balancer --load-balancer-name $ELB_NAME --listeners $LISTENERS --subnets $SUBNET_IDS --security-groups $SECURITY_GROUP_IDS >/dev/null 

aws elb configure-health-check --load-balancer-name $ELB_NAME --health-check $HEALTH_CHECK >/dev/null 

#aws elb add-tags --load-balancer-names $ELB_NAME --tags $TAGS

echo -e "aws_ElbName:\t$ELB_NAME"

exit 0

