#!/bin/bash

HOST_DIR_NAME=${PWD}

#Include functions
source $(dirname $0)/../script/__functions.sh

msg_warn "Check prerequisites..."
#Check prerequisites
check_command_exists "multipass"

# Stop main VM
multipass stop ${VM_MAIN_NAME}

# Stop all node VMs
max_node_num=$(multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}' | sed 's/${VM_NODE_PREFIX}//' | sort -n | tail -1)
counter=1

while [ $counter -le $max_node_num ]; do
    vm_name="${VM_NODE_PREFIX}${counter}"
    multipass stop $vm_name
    ((counter++))
done

msg_info "All VMs stopped."
multipass list