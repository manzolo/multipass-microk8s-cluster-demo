#!/bin/bash

#Include functions
source $(dirname $0)/script/__functions.sh

echo -e "${BROWN}== Clean vms cluster${NC}"

multipass list | grep k8s-node | awk '{print $1}' | while read node; do
echo "remove $node =="
multipass delete $node
done

echo "remove k8s-main =="
multipass delete k8s-main
multipass purge
multipass list

rm -rf "./script/_test.sh"
rm -rf "./config/hosts"

echo -e "${GREEN}== Vms cluster clear${NC}"
