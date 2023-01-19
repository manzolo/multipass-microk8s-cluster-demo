#!/bin/bash
echo "== Clean vms cluster"

multipass delete k8s-node2
multipass delete k8s-node1
multipass delete k8s-main
multipass purge
multipass list

echo "== Vms cluster clear"
