#!/bin/bash

set -e

USAGE="Usage: userdata-create.sh [environment] [service]"

if [ ! $# = 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2

WORKING_DIR=./working
mkdir -p $WORKING_DIR

USERDATA_FILE=$WORKING_DIR/$ENVIRONMENT-$SERVICE

[ -f $USERDATA_FILE ] && rm $USERDATA_FILE

cat userdata/header.global >> $USERDATA_FILE

case $SERVICE in
  "dummy")
    cat userdata/service.global >> $USERDATA_FILE
    ;;
esac

[ -f userdata/$SERVICE ] && cat userdata/$SERVICE >> $USERDATA_FILE

cat userdata/footer.global >> $USERDATA_FILE

sed -i -e "s/%%ENVIRONMENT%%/$ENVIRONMENT/g" $USERDATA_FILE

echo $USERDATA_FILE

exit 0

