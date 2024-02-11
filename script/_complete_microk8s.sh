#!/bin/bash
source $(dirname $0)/__functions.sh

HOST_DIR_NAME=$1

rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
rm -rf ${HOST_DIR_NAME}/script/_test.sh
rm -rf ${HOST_DIR_NAME}/config/hosts

kubectl apply -f ${HOST_DIR_NAME}/config/demo-go.yaml
kubectl rollout status deployment/demo-go -n demo-go

kubectl apply -f ${HOST_DIR_NAME}/config/demo-php.yaml
kubectl rollout status deployment/demo-php -n demo-php

#kubectl scale deployment demo-go --replicas=6 -n demo-go
msg_warn "Waiting deploy start..."
sleep 10
msg_warn "kubectl get node"
kubectl get node
msg_warn "kubectl get all -o wide -n demo-go"
kubectl get all -o wide -n demo-go
msg_warn "kubectl get all -o wide -n demo-php"
kubectl get all -o wide -n demo-php



