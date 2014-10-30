#!/bin/bash

# requirements;
# aws-cli v1.4
# curl
# aws account environment variables are set

set -e

USAGE="Usage: environments-create.sh [environment]"

if [ $# -ne 1 ]; then 
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1

SLEEP_NAT_PENDING=5
SLEEP_RDS_CREATING=5

# vpc

exec 5>&1
VPC_DATA=$(bash vpcs-create.sh $ENVIRONMENT | tee >(cat - >&5))

VPC_ID=$(echo "$VPC_DATA" | grep "aws_VpcId" | cut -f2)
SUBNET_ID_PRIVATE=$(echo "$VPC_DATA" | grep "aws_SubnetIdPrivate" | cut -f2)
SUBNET_ID_PUBLIC=$(echo "$VPC_DATA" | grep "aws_SubnetIdPublic" | cut -f2)
SUBNET_ID_RDS=$(echo "$VPC_DATA" | grep "aws_SubnetIdRds" | cut -f2)
SECURITY_GROUP_ID_ELB=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdElb" | cut -f2)
SECURITY_GROUP_ID_MONGO=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdMongo" | cut -f2)
SECURITY_GROUP_ID_REDIS=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdRedis" | cut -f2)
SECURITY_GROUP_ID_ELASTIC=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdElastic" | cut -f2)
SECURITY_GROUP_ID_SERVICE=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdService" | cut -f2)
SECURITY_GROUP_ID_DEPLOY=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdDeploy" | cut -f2)
SECURITY_GROUP_ID_RDS=$(echo "$VPC_DATA" | grep "aws_SecurityGroupIdRds" | cut -f2)
AVAILABILITY_ZONE_RDS=$(echo "$VPC_DATA" | grep "aws_AvailabilityZoneRds" | cut -f2)

# rds

DB_INSTANCE_ID_PGSQL=$(bash rds-create.sh $ENVIRONMENT pgsql $VPC_ID $SUBNET_ID_PRIVATE $SUBNET_ID_RDS $SECURITY_GROUP_ID_RDS $AVAILABILITY_ZONE_RDS | grep aws_DbInstanceId | cut -f2)
echo -e "aws_DbInstanceIdPgsql:\t$DB_INSTANCE_ID_PGSQL"

# s3 buckets

BUCKET_NAME_DUMMY=$(bash s3-create.sh $ENVIRONMENT dummy | grep aws_BucketName | cut -f2)
echo -e "aws_BucketNameDummy:\t$BUCKET_NAME_DUMMY"

# instances

INSTANCE_ID_MONGO=$(bash instances-create.sh $ENVIRONMENT mongo $VPC_ID $SECURITY_GROUP_ID_MONGO $SUBNET_ID_PRIVATE | grep "aws_InstanceId" | cut -f2) 
echo -e "aws_InstanceIdMongo:\t$INSTANCE_ID_MONGO"

INSTANCE_ID_REDIS=$(bash instances-create.sh $ENVIRONMENT redis $VPC_ID $SECURITY_GROUP_ID_REDIS $SUBNET_ID_PRIVATE | grep "aws_InstanceId" | cut -f2)
echo -e "aws_InstanceIdRedis:\t$INSTANCE_ID_REDIS"

INSTANCE_ID_ELASTIC=$(bash instances-create.sh $ENVIRONMENT elastic $VPC_ID $SECURITY_GROUP_ID_ELASTIC $SUBNET_ID_PRIVATE | grep "aws_InstanceId" | cut -f2)
echo -e "aws_InstanceIdElastic:\t$INSTANCE_ID_ELASTIC"

# elbs

ELB_NAME_DUMMY=$(bash elbs-create.sh $ENVIRONMENT dummy $SUBNET_ID_PUBLIC $SECURITY_GROUP_ID_ELB | grep "aws_ElbName" | cut -f2)
echo -e "aws_ElbNameDummy:\t$ELB_NAME_DUMMY"

# launch configs

bash lcs-create.sh $ENVIRONMENT dummy $SECURITY_GROUP_ID_SERVICE
bash lcs-create.sh $ENVIRONMENT go $SECURITY_GROUP_ID_DEPLOY

# asgs

bash asgs-create.sh $ENVIRONMENT dummy $SUBNET_ID_PRIVATE $ELB_NAME_DUMMY
bash asgs-create.sh $ENVIRONMENT go $SUBNET_ID_PRIVATE

# wait for NAT

INSTANCE_ID_NAT=$(echo "$VPC_DATA" | grep "aws_InstanceIdNat" | cut -f2)

IP_ADDRESS_NAT=$(aws ec2 describe-instances --output text --filters Name=tag:Name,Values=$ENVIRONMENT-nat | grep -m 1 "^ASSOCIATION" | cut -f4)
echo -e "aws_IpAddressNat:\t$IP_ADDRESS_NAT"

nc -w 1 -z $IP_ADDRESS_NAT 22 || true
RETVAL=$?
while [ ! $RETVAL -eq 0 ]; do
  sleep $SLEEP_NAT_PENDING
  nc -w 1 -z $IP_ADDRESS_NAT 22 || true
  RETVAL=$?
done

# data init

bash instances-init.sh $ENVIRONMENT mongo
bash instances-init.sh $ENVIRONMENT elastic
bash instances-init.sh $ENVIRONMENT redis

bash instances-init.sh $ENVIRONMENT dummy

while [ ! "$(aws rds describe-db-instances --output text --db-instance-identifier $DB_INSTANCE_ID_PGSQL | grep "^DBINSTANCES" | cut -f8)" = "available" ]; do
  sleep $SLEEP_RDS_CREATING
done

bash instances-init.sh $ENVIRONMENT dummy
bash instances-init.sh $ENVIRONMENT go

exit 0

