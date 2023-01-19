#!/bin/bash
HOST_DIR_NAME=$1
IP="$(hostname)"
JOINCMD=$(microk8s add-node | sed '/microk8s/p' | sed '6!d')
echo "${JOINCMD##Join node with: }" > ${HOST_DIR_NAME}/script/_join_node.sh
chmod a+x ${HOST_DIR_NAME}/script/_join_node.sh
