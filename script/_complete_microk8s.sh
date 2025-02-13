#!/bin/bash
source $(dirname $0)/__functions.sh

rm -rf script/_join_node.sh
rm -rf script/_test.sh
rm -rf config/hosts

kubectl apply -f config/demo-go.yaml
kubectl rollout status deployment/demo-go -n demo-go

kubectl apply -f config/demo-php.yaml
kubectl rollout status deployment/demo-php -n demo-php

#kubectl scale deployment demo-go --replicas=6 -n demo-go
msg_warn "Waiting deploy start..."
sleep 10
msg_warn "kubectl get node"
kubectl get node
msg_info "If you want to scale 'demo-go' to 20 pod"
msg_warn "multipass exec k8s-main -- kubectl scale deployment demo-go --replicas=20 -n demo-go"
msg_warn "multipass exec k8s-main -- kubectl get all -o wide -n demo-go"

kubectl get all -o wide -n demo-go
msg_warn "multipass exec k8s-main -- kubectl get all -o wide -n demo-php"
kubectl get all -o wide -n demo-php



