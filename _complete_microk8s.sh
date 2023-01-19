#!/bin/bash
HOST_DIR_NAME=$1

sudo rm -rf ${HOST_DIR_NAME}/_join_node.sh

kubectl apply -f ${HOST_DIR_NAME}/go-deployment.yaml
kubectl rollout status deployment/go-deployment
kubectl scale deployment go-deployment --replicas=6
echo "Waiting deploy start..."
sleep 10
echo "kubectl get node:"
kubectl get node
echo "kubectl get all -o wide:"
kubectl get all -o wide