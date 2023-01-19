#!/bin/bash
HOST_DIR_NAME=$1
IP="$(hostname)"
#JOINCMD=$(microk8s add-node | sed '/microk8s/p' | sed '6!d')
rm -rf ${HOST_DIR_NAME}/_join_node.sh
JOINCMD=$(sudo microk8s add-node | sed '/microk8s/p' | sed '6!d' | sed -r 's|microk8s join (\b[0-9]{1,3}\.){3}[0-9]{1,3}\b:|microk8s join k8s-main:|')
echo "${JOINCMD##Join node with: }" > ${HOST_DIR_NAME}/script/_join_node.sh
chmod a+x ${HOST_DIR_NAME}/script/_join_node.sh
