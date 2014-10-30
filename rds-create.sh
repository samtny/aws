#!/bin/bash

set -e

USAGE="Usage: rds-create.sh [environment] [pgsql] [vpc-id] [subnet-id-1] [subnet-id-2] [security-group-ids] [availability-zone]"

if [ "$#" -ne 7 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
VPC_ID=$3
SUBNET_ID_1=$4
SUBNET_ID_2=$5
SECURITY_GROUP_IDS=$6
AVAILABILITY_ZONE=$7

RESOURCE_PREFIX=$ENVIRONMENT
DB_RESOURCE_PREFIX=aws_$ENVIRONMENT

SLEEP_RESOURCE_CREATE=2

INSTANCE_CLASS="db.m3.medium"

DB_SUBNET_GROUP_NAME=$RESOURCE_PREFIX-$SERVICE
aws rds create-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP_NAME --db-subnet-group-description $DB_SUBNET_GROUP_NAME --subnet-ids $SUBNET_ID_1 $SUBNET_ID_2

RETVAL=-1
while [ ! $RETVAL = 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws rds describe-db-subnet-groups --db-subnet-group-name $DB_SUBNET_GROUP_NAME || true)
  RETVAL=$?
done

DB_SEPARATOR="_"
DB_NAME=$DB_RESOURCE_PREFIX$DB_SEPARATOR$SERVICE
DB_INSTANCE_ID=$RESOURCE_PREFIX-$SERVICE

aws rds create-db-instance --db-name $DB_NAME --db-instance-identifier $DB_INSTANCE_ID --allocated-storage 5 --db-instance-class $INSTANCE_CLASS --engine postgres --master-username $DB_RESOURCE_PREFIX$DB_SEPARATOR$SERVICE --master-user-password $DB_RESOURCE_PREFIX$DB_SEPARATOR$SERVICE --vpc-security-group-ids $SECURITY_GROUP_IDS --availability-zone $AVAILABILITY_ZONE --db-subnet-group-name $DB_SUBNET_GROUP_NAME --no-multi-az --port 5432 --backup-retention-period 0

RETVAL=-1
while [ ! $RETVAL = 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID || true)
  RETVAL=$?
done

echo -e "aws_DbInstanceId:\t$DB_INSTANCE_ID"

exit 0

