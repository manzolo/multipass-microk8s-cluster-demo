#!/bin/bash

HOST_DIR_NAME=${PWD}

#Include functions
source $(dirname $0)/script/__functions.sh

msg_warn "Check prerequisites..."
#Check prerequisites
check_command_exists "multipass"

# Stop main VM
multipass start k8s-main

# Stop all node VMs
max_node_num=$(multipass list | grep k8s-node | awk '{print $1}' | sed 's/k8s-node//' | sort -n | tail -1)
counter=1

while [ $counter -le $max_node_num ]; do
    vm_name="k8s-node${counter}"
    multipass start $vm_name
    ((counter++))
done

msg_info "All VMs started."
multipass list