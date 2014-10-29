#!/bin/bash

set -e

USAGE="Usage: vpcs-create.sh [environment]"

if [ ! "$#" -eq  1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1

RESOURCE_PREFIX="$ENVIRONMENT"

SLEEP_RESOURCE_CREATE=2
SLEEP_INSTANCE_PENDING=10

CIDR_BLOCK_OFFICE=38.108.0.0/16
CIDR_BLOCK_VPC=10.0.0.0/16
CIDR_BLOCK_PRIVATE=10.0.1.0/24
CIDR_BLOCK_PUBLIC=10.0.0.0/24
CIDR_BLOCK_RDS=10.0.2.0/24

THIS_IP_PROVIDER=ipinfo.io/ip

CIDR_BLOCK_THIS="$(curl -s $THIS_IP_PROVIDER)/32"

AVAILABILITY_ZONE_PRIVATE="us-east-1b"
AVAILABILITY_ZONE_PUBLIC="us-east-1b"
AVAILABILITY_ZONE_RDS="us-east-1c"

echo -e "aws_AvailabilityZonePrivate:\t$AVAILABILITY_ZONE_PRIVATE"
echo -e "aws_AvailabilityZonePublic:\t$AVAILABILITY_ZONE_PUBLIC"
echo -e "aws_AvailabilityZoneRds:\t$AVAILABILITY_ZONE_RDS"

TAGS="Key=Name,Value=$RESOURCE_PREFIX"

VPC_ID=$(aws ec2 create-vpc --cidr-block $CIDR_BLOCK_VPC | grep VpcId | cut -d':' -f2 | cut -d'"' -f2)

RETVAL=-1
while [ $RETVAL -ne 0 ]; do
  sleep $SLEEP_RESOURCE_CREATE
  (aws ec2 describe-vpcs --vpc-ids $VPC_ID >/dev/null || true)
  RETVAL=$?
done

aws ec2 create-tags --tags $TAGS --resources $VPC_ID >/dev/null 

echo -e "aws_VpcId:\t$VPC_ID"

# subnets

SUBNET_ID_PRIVATE=$(./subnets-create.sh $(echo $RESOURCE_PREFIX)-private $VPC_ID $CIDR_BLOCK_PRIVATE $AVAILABILITY_ZONE_PRIVATE | grep aws_SubnetId | cut -f2)
echo -e "aws_SubnetIdPrivate:\t$SUBNET_ID_PRIVATE"

SUBNET_ID_PUBLIC=$(./subnets-create.sh $(echo $RESOURCE_PREFIX)-public $VPC_ID $CIDR_BLOCK_PUBLIC $AVAILABILITY_ZONE_PUBLIC | grep aws_SubnetId | cut -f2)
echo -e "aws_SubnetIdPublic:\t$SUBNET_ID_PUBLIC"

SUBNET_ID_RDS=$(./subnets-create.sh $(echo $RESOURCE_PREFIX)-rds $VPC_ID $CIDR_BLOCK_RDS $AVAILABILITY_ZONE_RDS | grep aws_SubnetId | cut -f2)
echo -e "aws_SubnetIdRds:\t$SUBNET_ID_RDS"

# security groups

SECGRP_ID_DEPLOY=$(./securitygroups-create.sh $RESOURCE_PREFIX-deploy $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdDeploy:\t$SECGRP_ID_DEPLOY"

SECGRP_ID_NAT=$(./securitygroups-create.sh $RESOURCE_PREFIX-nat $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdNat:\t$SECGRP_ID_NAT"

SECGRP_ID_ELB=$(./securitygroups-create.sh $RESOURCE_PREFIX-elb $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdElb:\t$SECGRP_ID_ELB"

SECGRP_ID_SERVICE=$(./securitygroups-create.sh $RESOURCE_PREFIX-service $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdService:\t$SECGRP_ID_SERVICE"

SECGRP_ID_MONGO=$(./securitygroups-create.sh $RESOURCE_PREFIX-mongo $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdMongo:\t$SECGRP_ID_MONGO"

SECGRP_ID_REDIS=$(./securitygroups-create.sh $RESOURCE_PREFIX-redis $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdRedis:\t$SECGRP_ID_REDIS"

SECGRP_ID_ELASTIC=$(./securitygroups-create.sh $RESOURCE_PREFIX-elastic $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdElastic:\t$SECGRP_ID_ELASTIC"

SECGRP_ID_RDS=$(./securitygroups-create.sh $RESOURCE_PREFIX-rds $VPC_ID | grep aws_SecurityGroupId | cut -f2)
echo -e "aws_SecurityGroupIdRds:\t$SECGRP_ID_RDS"

# security group ingress

aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_DEPLOY --source-group $SECGRP_ID_NAT --protocol tcp --port 22 >/dev/null  
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_SERVICE --source-group $SECGRP_ID_NAT --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_MONGO --source-group $SECGRP_ID_NAT --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_REDIS --source-group $SECGRP_ID_NAT --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_ELASTIC --source-group $SECGRP_ID_NAT --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --source-group $SECGRP_ID_DEPLOY --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_SERVICE --source-group $SECGRP_ID_DEPLOY --protocol tcp --port 22 >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_SERVICE --cidr $CIDR_BLOCK_PUBLIC --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --cidr $CIDR_BLOCK_OFFICE --protocol tcp --port 22 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --cidr $CIDR_BLOCK_THIS --protocol tcp --port 22 >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_ELB --cidr 0.0.0.0/0 --protocol tcp --port 80 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --cidr $CIDR_BLOCK_PRIVATE --protocol tcp --port 80 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --cidr $CIDR_BLOCK_PRIVATE --protocol tcp --port 443 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_ELB --cidr 0.0.0.0/0 --protocol tcp --port 443 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_RDS --source-group $SECGRP_ID_SERVICE --protocol tcp --port 5432 >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_RDS --source-group $SECGRP_ID_DEPLOY --protocol tcp --port 5432 >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_REDIS --source-group $SECGRP_ID_SERVICE --protocol tcp --port 6379 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --source-group $SECGRP_ID_DEPLOY --protocol tcp --port 8081 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --source-group $SECGRP_ID_SERVICE --protocol tcp --port 8081 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --source-group $SECGRP_ID_DEPLOY --protocol tcp --port 8153 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_NAT --source-group $SECGRP_ID_DEPLOY --protocol tcp --port 8154 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_SERVICE --source-group $SECGRP_ID_ELB --protocol tcp --port 9000 >/dev/null  
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_ELASTIC --source-group $SECGRP_ID_SERVICE --protocol tcp --port 9200 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_ELASTIC --source-group $SECGRP_ID_SERVICE --protocol tcp --port 9300 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_MONGO --source-group $SECGRP_ID_SERVICE --protocol tcp --port 27017 >/dev/null 
aws ec2 authorize-security-group-ingress --group-id $SECGRP_ID_MONGO --source-group $SECGRP_ID_ELASTIC --protocol tcp --port 27017 >/dev/null 

# security group egress

aws ec2 authorize-security-group-egress --port 22 --protocol tcp --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 
aws ec2 authorize-security-group-egress --port 80 --protocol tcp --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 
aws ec2 authorize-security-group-egress --port 443 --protocol tcp --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 
aws ec2 authorize-security-group-egress --port 8081 --protocol tcp --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 
aws ec2 authorize-security-group-egress --port 8153 --protocol tcp --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 
aws ec2 authorize-security-group-egress --port 8154 --protocol tcp --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 
aws ec2 revoke-security-group-egress --protocol -1 --cidr 0.0.0.0/0 --group-id $SECGRP_ID_NAT >/dev/null 

# gateway + public route table + public route table associations + public routes 

GATEWAY_ID=$(./gateways-create.sh $ENVIRONMENT $VPC_ID | grep aws_GatewayId | cut -f2)
echo -e "aws_InternetGatewayId:\t$GATEWAY_ID"

ROUTE_TABLE_ID_PUBLIC=$(./routetables-create.sh $RESOURCE_PREFIX-public $VPC_ID | grep aws_RouteTableId | cut -f2)
echo -e "aws_RouteTableIdPublic:\t$ROUTE_TABLE_ID_PUBLIC"

aws ec2 associate-route-table --subnet-id $SUBNET_ID_PUBLIC --route-table-id $ROUTE_TABLE_ID_PUBLIC >/dev/null 

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID_PUBLIC --destination-cidr-block 0.0.0.0/0 --gateway-id $GATEWAY_ID >/dev/null 

# nat instance + private route table + private route table associations + private routes

INSTANCE_ID_NAT=$(bash instances-create.sh $ENVIRONMENT nat $VPC_ID $SECGRP_ID_NAT $SUBNET_ID_PUBLIC | grep aws_InstanceId | cut -f2)
while [ "$(aws ec2 describe-instances --instance-ids $INSTANCE_ID_NAT --output text | grep STATE | grep -v STATEREASON | cut -f3)" = "pending" ]; do
  sleep $SLEEP_RESOURCE_CREATE
done
echo -e "aws_InstanceIdNat:\t$INSTANCE_ID_NAT"

ALLOCATION_ID_NAT=$(aws ec2 allocate-address --domain vpc | grep AllocationId | cut -d':' -f2 | cut -d'"' -f2)
while [ ! "$(aws ec2 describe-addresses --output text --allocation-id $ALLOCATION_ID_NAT | grep '^ADDRESSES' | cut -f2)" = "$ALLOCATION_ID_NAT" ]; do
  sleep $SLEEP_RESOURCE_CREATE
done
aws ec2 associate-address --instance-id $INSTANCE_ID_NAT --allocation-id $ALLOCATION_ID_NAT >/dev/null
echo -e "aws_AllocationIdNat:\t$ALLOCATION_ID_NAT"

ROUTE_TABLE_ID_PRIVATE=$(./routetables-create.sh $RESOURCE_PREFIX-private $VPC_ID | grep aws_RouteTableId | cut -f2)
echo -e "aws_RouteTableIdPrivate:\t$ROUTE_TABLE_ID_PRIVATE"

aws ec2 associate-route-table --subnet-id $SUBNET_ID_PRIVATE --route-table-id $ROUTE_TABLE_ID_PRIVATE >/dev/null

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID_PRIVATE --destination-cidr-block 0.0.0.0/0 --instance-id $INSTANCE_ID_NAT >/dev/null 

# rds route table associations

aws ec2 associate-route-table --subnet-id $SUBNET_ID_RDS --route-table-id $ROUTE_TABLE_ID_PRIVATE >/dev/null

exit 0

