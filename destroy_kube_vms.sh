#!/bin/bash
echo "== Clean vms cluster"

multipass list | grep k8s-node | awk '{print $1}' | while read node; do
echo "remove $node =="
multipass delete $node
done

echo "remove k8s-main =="
multipass delete k8s-main
multipass purge
multipass list

rm -rf "./script/_test.sh"

echo "== Vms cluster clear"
