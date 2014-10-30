#!/bin/bash

USAGE="Usage: s3-create.sh [environment] [variant]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
VARIANT=$2

BUCKET_NAME=$VARIANT-$ENVIRONMENT

aws s3api create-bucket --bucket $BUCKET_NAME --grant-full-control 'emailaddress="me@me.com"' >/dev/null

echo -e "aws_BucketName:\t$BUCKET_NAME"

exit 0

