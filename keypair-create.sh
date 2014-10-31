#!/bin/bash

set -e

USAGE="Usage: keypair-create.sh [environment]"

if [ $# -ne 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1

PEM=~/.ssh/$ENVIRONMENT.pem

if [ -f $PEM ]; then
  exit 1
fi

touch $PEM && chmod 600 $PEM

aws ec2 create-key-pair --output text --key-name $ENVIRONMENT >> $PEM

chmod 400 $PEM

exit 0

