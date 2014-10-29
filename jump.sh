#!/bin/bash

set -e
set -x
USAGE="Usage: jump.sh [environment] [service] [command] [args...]"

if [ $# -lt 1 ]; then
  echo "$USAGE"
  exit 1
fi

ENVIRONMENT=$1
SERVICE=$2
COMMAND=$3
ARGS=$4

SSH_IDENTITY=~/.ssh/$ENVIRONMENT-serverkey.pem

SCRIPT_DIR="$(cd "$( dirname "$0" )" && pwd)"

IP_ADDRESS_NAT=$(bash $SCRIPT_DIR/eips-get.sh $ENVIRONMENT nat)

[ "$SERVICE" != "" ] && IP_ADDRESS_TARGET=$(bash $SCRIPT_DIR/ips-get.sh $ENVIRONMENT $SERVICE)
[ "$ARGS" != "" ] && ARGS=$(echo "$@" | cut -d' ' -f4-)

SSH_NAT="ssh -i $SSH_IDENTITY ec2-user@$IP_ADDRESS_NAT"

IP_COUNT=$(echo "$IP_ADDRESS_TARGET" | wc -l)

if [ $IP_COUNT -gt 1 ]; then
  echo -e "Found targets:\n\n$IP_ADDRESS_TARGET\n"
  read -p "Choice [1-$IP_COUNT]: " CHOICE
  IP_ADDRESS_TARGET=$(echo "$IP_ADDRESS_TARGET" | sed -n "$CHOICE,$CHOICE p") 
fi

if [ "$IP_ADDRESS_TARGET" = "" ]; then
  $SSH_NAT $COMMAND $ARGS
else
  ssh -i $SSH_IDENTITY -o StrictHostKeyChecking=no -o ProxyCommand="$SSH_NAT -W %h:%p" ubuntu@$IP_ADDRESS_TARGET $COMMAND $ARGS
fi

exit 0

