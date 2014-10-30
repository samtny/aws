#!/bin/bash

set -e

USAGE="Usage: gocdagents-enable.sh [environment] [gocd-server-url] [user] [password]"

if [ $# -ne 2 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
GOCD_SERVER_URL=$2

GUID=$(./gocdagents-guid.sh $ENVIRONMENT)

curl --user $USER:$PASSWORD --data '' http://$GOCD_SERVER_URL:8153/go/api/agents/$GUID/enable

exit 0

