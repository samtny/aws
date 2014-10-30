#!/bin/bash

set -e

USAGE="Usage: gocdagents-guid.sh [environment]"

if [ $# -ne 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1

echo $(../ssh-jump.sh $ENVIRONMENT go cat /var/lib/go-agent/config/guid.txt)

exit 0

