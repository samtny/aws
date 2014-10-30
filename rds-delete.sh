#!/bin/bash

set -e

USAGE="rds-delete.sh [environment] [service]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

SLEEP_RESOURCE_DELETE=2

DESCRIBE_DB_INSTANCES=$(aws rds describe-db-instances --output text --db-instance-identifier $ENVIRONMENT-$SERVICE)

if [ "$DESCRIBE_DB_INSTANCES" = "" ]; then
  echo -e "aws_Status:\tnomatch"
  exit 0
fi

DB_INSTANCE_IDS=$(echo "$DESCRIBE_DB_INSTANCES" | grep "^DBINSTANCES" | cut -f7)

echo -e "You are about to terminate these rds instances:\n\n$DB_INSTANCE_IDS"
echo -en "\nAre you sure? [N|y]: "

read CONTINUE && [ "$CONTINUE" = "y" ] || exit 0

DB_SUBNET_GROUPS=$(echo "$DESCRIBE_DB_INSTANCES" | grep "^DBSUBNETGROUP" | cut -f2)

(echo "$DB_INSTANCE_IDS" | xargs aws rds delete-db-instance --final-db-snapshot-identifier $ENVIRONMENT-$SERVICE-final-snapshot --db-instance-identifier >/dev/null || true) 

while [ "$DESCRIBE_DB_INSTANCES" != "" ]; do
  sleep $SLEEP_RESOURCE_DELETE
  DESCRIBE_DB_INSTANCES=$(aws rds describe-db-instances --output text --db-instance-identifier $ENVIRONMENT-$SERVICE || true)
done

if [ "$DB_SUBNET_GROUPS" != "" ]; then
  $(echo "$DB_SUBNET_GROUPS" | xargs aws rds delete-db-subnet-group --db-subnet-group-name)
  
  while [ "$DB_SUBNET_GROUPS" != "" ]; do
    sleep $SLEEP_RESOURCE_DELETE
    DB_SUBNET_GROUPS=$(aws rds describe-db-subnet-groups --db-subnet-group-name $DB_SUBNET_GROUPS || true)
  done
fi

echo -e "aws_Status:\tsuccess"

exit 0

