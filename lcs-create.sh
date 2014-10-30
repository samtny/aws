#!/bin/bash

set -e

USAGE="Usage: lcs-create.sh [environment] [service] [security-group-ids]"

if [ "$#" -ne 3 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
SECURITY_GROUP_IDS=$3

LC_NAME="$ENVIRONMENT-$SERVICE"
IMAGE_ID="ami-a217b2ca"
KEY_NAME="$ENVIRONMENT-serverkey"
INSTANCE_TYPE="t2.micro"

USER_DATA="file://$(./userdata-create.sh $ENVIRONMENT $SERVICE)"

case $SERVICE in
  "dummy_big")
    INSTANCE_TYPE="m3.xlarge"
    ;;
  "go")
    INSTANCE_TYPE="m3.large"
    IMAGE_ID="ami-eaa07f82"
    ;;
esac

aws autoscaling create-launch-configuration --launch-configuration-name $LC_NAME --image-id $IMAGE_ID --key-name $KEY_NAME --security-groups $SECURITY_GROUP_IDS --user-data $USER_DATA --instance-type $INSTANCE_TYPE >/dev/null

echo -e "aws_lcName$SERVICE:\t$LC_NAME"

exit 0

