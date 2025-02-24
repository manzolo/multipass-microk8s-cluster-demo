#!/bin/bash

set -e

# Include le funzioni
source "$(dirname "$0")/../script/__functions.sh"

# Load default values and environment variables
source "$(dirname "$0")/../script/__load_env.sh"

# Imposta le variabili di ambiente predefinite se non sono state fornite
HOST_DIR_NAME=${PWD}

# Function to check prerequisites
check_prerequisites() {
    msg_warn "Checking prerequisites..."
    check_command_exists "multipass" || { msg_error "Multipass is not installed or cannot be found. Exiting."; exit 1; }
}

# Function to clean temporary files
clean_temporary_files() {
    rm -rf "${HOST_DIR_NAME}/script/_test.sh"
}

# Function to create and configure node VM
create_and_configure_node_vm() {
    local current_counter=$(get_available_node_number)
    local node_name="${VM_NODE_PREFIX}${current_counter}"

    msg_warn "Creating VM: $node_name"
    clone_vm "$node_name"
    multipass start "$node_name"
    wait_for_microk8s_ready "$node_name"

    add_machine_to_dns "$node_name"
    multipass info "$node_name"

    multipass start "$VM_MAIN_NAME"
    wait_for_microk8s_ready "$VM_MAIN_NAME"
    sleep 5

    generate_join_command "$node_name"
}

# Function to generate join command
generate_join_command() {
    local node_name=$1

    msg_warn "Generating join cluster command for $VM_MAIN_NAME"
    multipass transfer script/__join_cluster_helper.sh "$VM_MAIN_NAME:/home/ubuntu/join_cluster_helper.sh"
    multipass transfer script/__rollout_pods.sh "$VM_MAIN_NAME:/home/ubuntu/rollout_pods.sh"

    local CLUSTER_JOIN_COMMAND=$(multipass exec "$VM_MAIN_NAME" -- /home/ubuntu/join_cluster_helper.sh)
    multipass exec "$VM_MAIN_NAME" -- rm -rf /home/ubuntu/join_cluster_helper.sh

    msg_warn "Installing microk8s on $node_name"
    multipass exec "$node_name" -- $CLUSTER_JOIN_COMMAND
}

# Main script execution
check_prerequisites
clean_temporary_files
create_and_configure_node_vm