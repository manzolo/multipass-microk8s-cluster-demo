#!/bin/bash
source $(dirname $0)/__functions.sh

HOST_DIR_NAME=$1

rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
rm -rf ${HOST_DIR_NAME}/script/_test.sh
rm -rf ${HOST_DIR_NAME}/config/hosts
kubectl apply -f ${HOST_DIR_NAME}/config/demo-go.yaml
kubectl rollout status deployment/demo-go
#kubectl scale deployment demo-go --replicas=6
msg_warn "Waiting deploy start..."
sleep 10
msg_warn "kubectl get node"
kubectl get node
msg_warn "kubectl get all -o wide"
kubectl get all -o wide

