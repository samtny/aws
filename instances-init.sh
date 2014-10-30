#!/bin/bash
set -x
set -e

USAGE="Usage: instances-init.sh [environment] [service]"

if [ ! $# -eq 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

SSH_IDENTITY_FILE=~/.ssh/$ENVIRONMENT-serverkey.pem

INIT_DIR=init
INIT_FILE=$SERVICE-init

SLEEP_INSTANCE_PENDING=5
SLEEP_USERDATA_PENDING=5
SLEEP_ENDPOINT_PENDING=10

WORKING_DIR=working
mkdir -p $WORKING_DIR

if [ -f $INIT_DIR/$INIT_FILE ]; then
  IP_ADDRESS_NAT=$(aws ec2 describe-instances --output text --filters Name=tag:Name,Values=$ENVIRONMENT-nat | grep -m 1  "^ASSOCIATION" | cut -f4)

  SUBNET_ID_PRIVATE=$(aws ec2 describe-subnets --output text --filters Name=tag:Name,Values=$ENVIRONMENT-private | grep "^SUBNETS" | cut -f8)

  IP_ADDRESS_SERVICE=$(aws ec2 describe-instances --output text --filters Name=tag:Name,Values=$ENVIRONMENT-$SERVICE | grep "^NETWORKINTERFACES" | grep $SUBNET_ID_PRIVATE | cut -f5)

  cp $INIT_DIR/$INIT_FILE $WORKING_DIR

  if grep -q '%%ENVIRONMENT%%' $WORKING_DIR/$INIT_FILE; then
    sed -i -e "s/%%ENVIRONMENT%%/$ENVIRONMENT/g" $WORKING_DIR/$INIT_FILE
  fi

  if grep -q '%%IP_ADDRESS_MONGO%%\|%%HOSTNAME_MONGO%%' $WORKING_DIR/$INIT_FILE; then
    IP_ADDRESS_MONGO=$(aws ec2 describe-instances --output text --filters Name=tag:Name,Values=$ENVIRONMENT-mongo | grep "^NETWORKINTERFACES" | grep $SUBNET_ID_PRIVATE | cut -f5)
    HOSTNAME_MONGO=$(echo ip-$IP_ADDRESS_MONGO | sed -e "s/\./-/g")
    sed -i -e "s/%%IP_ADDRESS_MONGO%%/$IP_ADDRESS_MONGO/g" $WORKING_DIR/$INIT_FILE
    sed -i -e "s/%%HOSTNAME_MONGO%%/$HOSTNAME_MONGO/g" $WORKING_DIR/$INIT_FILE
  fi

  if grep -q '%%IP_ADDRESS_REDIS%%' $WORKING_DIR/$INIT_FILE; then
    IP_ADDRESS_REDIS=$(aws ec2 describe-instances --output text --filters Name=tag:Name,Values=$ENVIRONMENT-redis | grep "^NETWORKINTERFACES" | grep $SUBNET_ID_PRIVATE | cut -f5)
    sed -i -e "s/%%IP_ADDRESS_REDIS%%/$IP_ADDRESS_REDIS/g" $WORKING_DIR/$INIT_FILE
  fi

  if grep -q '%%IP_ADDRESS_ELASTIC%%' $WORKING_DIR/$INIT_FILE; then
    IP_ADDRESS_ELASTIC=$(aws ec2 describe-instances --output text --filters Name=tag:Name,Values=$ENVIRONMENT-elastic | grep "^NETWORKINTERFACES" | grep $SUBNET_ID_PRIVATE | cut -f5)
    sed -i -e "s/%%IP_ADDRESS_ELASTIC%%/$IP_ADDRESS_ELASTIC/g" $WORKING_DIR/$INIT_FILE
  fi

  if grep -q '%%IP_ADDRESS_RDS%%' $WORKING_DIR/$INIT_FILE; then
    DESCRIBE_DB_INSTANCES=$(aws rds describe-db-instances --output text --db-instance-identifier $ENVIRONMENT-pgsql)

    if [ "$DESCRIBE_DB_INSTANCES" != "" ]; then
      ENDPOINT=$(echo "$DESCRIBE_DB_INSTANCES" | grep "^ENDPOINT")

      while [ "$ENDPOINT" = "" ]; do
        sleep $SLEEP_ENDPOINT_PENDING
        ENDPOINT=$(aws rds describe-db-instances --output text --db-instance-identifier $ENVIRONMENT-pgsql | grep "^ENDPOINT")
      done

      IP_ADDRESS_RDS=$(echo "$ENDPOINT" | cut -f2 | xargs dig +short)

      sed -i -e "s/%%IP_ADDRESS_RDS%%/$IP_ADDRESS_RDS/g" $WORKING_DIR/$INIT_FILE
    fi
  fi

  while [ ! "$(ssh -i $SSH_IDENTITY_FILE -o StrictHostKeyChecking=no -o ConnectTimeout=1 ec2-user@$IP_ADDRESS_NAT nc -w 1 -zv $IP_ADDRESS_SERVICE 22 | grep "succeed" | cut -d' ' -f3 | xargs echo)" = "$IP_ADDRESS_SERVICE" ]; do
    sleep $SLEEP_INSTANCE_PENDING
  done

  while [ ! "$(ssh -i $SSH_IDENTITY_FILE -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $SSH_IDENTITY_FILE ec2-user@$IP_ADDRESS_NAT -W %h:%p" ubuntu@$IP_ADDRESS_SERVICE cat userdata | grep -m 1 "done")" = "done" ]; do
    sleep $SLEEP_USERDATA_PENDING
  done
  
  scp -i $SSH_IDENTITY_FILE -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $SSH_IDENTITY_FILE ec2-user@$IP_ADDRESS_NAT -W %h:%p" $WORKING_DIR/$INIT_FILE ubuntu@$IP_ADDRESS_SERVICE:$INIT_FILE

  ssh -i $SSH_IDENTITY_FILE -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $SSH_IDENTITY_FILE ec2-user@$IP_ADDRESS_NAT -W %h:%p" ubuntu@$IP_ADDRESS_SERVICE bash $INIT_FILE
fi

exit 0

