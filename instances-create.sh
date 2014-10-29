#!/bin/bash

set -e

USAGE="Usage: instances-create.sh [environment] [nat|mongo|redis|elastic|go] [vpc-id] [security-group-ids] [subnet-id] [elb-name]"

if [ "$#" -lt 5 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
VPC_ID=$3
SECURITY_GROUP_IDS=$4
SUBNET_ID=$5
ELB_NAME=$6
ALLOCATION_ID=$7

RESOURCE_PREFIX=$ENVIRONMENT

SLEEP_RESOURCE_CREATE=2

INSTANCE_TYPE="t2.micro"
KEY_NAME="$ENVIRONMENT-serverkey"
EXTRA_ARGS=""
IMAGE_ID="ami-a217b2ca"

USER_DATA="file://$(./userdata-create.sh $ENVIRONMENT $SERVICE)"

case $SERVICE in
  "nat")
    IMAGE_ID="ami-6e9e4b06"
    ;;
  "mongo")
    INSTANCE_TYPE="m3.large"
    EXTRA_ARGS='--block-device-mappings [{"DeviceName":"/dev/xvdf","Ebs":{"VolumeSize":100}},{"DeviceName":"/dev/xvdg","Ebs":{"VolumeSize":100}}]'
    ;;
  "elastic")
    INSTANCE_TYPE="m3.large"
    ;;
esac

RUN_INSTANCES_RESULT=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --user-data $USER_DATA --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_IDS --subnet-id $SUBNET_ID $EXTRA_ARGS)

INSTANCE_ID=$(echo "$RUN_INSTANCES_RESULT" | grep InstanceId | cut -d':' -f2 | cut -d'"' -f2)

RETVAL=-1
while [ $RETVAL -ne 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws ec2 describe-instances --instance-ids $INSTANCE_ID || true)
  RETVAL=$?
done

while [ "$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep STATE | grep -v STATEREASON | cut -f3)" = "pending" ]; do
  sleep $SLEEP_RESOURCE_CREATE
done

echo -e "aws_InstanceId:\t$INSTANCE_ID"

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$RESOURCE_PREFIX-$SERVICE Key=Environment,Value=$RESOURCE_PREFIX >/dev/null

[ "$ELB_NAME" != "" ] && aws elb register-instances-with-load-balancer --load-balancer-name $ELB_NAME --instances $INSTANCE_ID >/dev/null

case $SERVICE in
  "nat")
    aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --no-source-dest-check >/dev/null
    ;;
esac

exit 0

