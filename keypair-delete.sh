#!/bin/bash

USAGE="Usage: keypair-delete.sh [environment]"

if [ $# -ne 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1

PEM=~/.ssh/$ENVIRONMENT.pem

aws ec2 delete-key-pair --output text --key-name $ENVIRONMENT >> /dev/null

[ -f $PEM ] && chmod 600 $PEM && rm $PEM

exit 0

