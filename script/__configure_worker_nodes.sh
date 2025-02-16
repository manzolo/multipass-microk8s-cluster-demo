#!/bin/bash

msg_info "=== Task 2: Configuring worker nodes ==="

for ((counter=1; counter<=instances; counter++)); do
    node_vm="${VM_NODE_PREFIX}$counter"
    
    ## Generate join command on the main VM
    msg_warn "Generating join cluster command on $VM_MAIN_NAME"
    run_command_on_node $VM_MAIN_NAME "script/_join_cluster_helper.sh"

    ## Install microk8s on the worker node
    msg_warn "Installing microk8s on $node_vm"
    run_command_on_node "$node_vm" "script/_install_microk8s.sh"
done