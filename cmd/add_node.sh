#!/bin/bash

set -e

# Include le funzioni
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

# Imposta le variabili di ambiente predefinite se non sono state fornite
HOST_DIR_NAME=${PWD}

# Controlla i prerequisiti
msg_warn "Checking prerequisites..."
check_command_exists "multipass" || { msg_error "Multipass is not installed or cannot be found. Exiting."; exit 1; }

# Pulisce i file temporanei
rm -rf "${HOST_DIR_NAME}/script/_test.sh"

current_counter=$(get_available_node_number)

# Create node VMs
msg_warn "Creating VM: ${VM_NODE_PREFIX}${current_counter}"
clone_vm "${VM_NODE_PREFIX}${current_counter}"
multipass start "${VM_NODE_PREFIX}${current_counter}"
wait_for_microk8s_ready "${VM_NODE_PREFIX}${current_counter}"

add_machine_to_dns "${VM_NODE_PREFIX}${current_counter}"

multipass info "${VM_NODE_PREFIX}${current_counter}"
multipass start "$VM_MAIN_NAME"

wait_for_microk8s_ready "$VM_MAIN_NAME"

sleep 5

msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
multipass transfer script/__join_cluster_helper.sh $VM_MAIN_NAME:/home/ubuntu/join_cluster_helper.sh
multipass transfer script/__rollout_pods.sh $VM_MAIN_NAME:/home/ubuntu/rollout_pods.sh

# Esegui lo script per creare il join al cluster
CLUSTER_JOIN_COMMAND=$(multipass exec $VM_MAIN_NAME -- "/home/ubuntu/join_cluster_helper.sh")
multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/join_cluster_helper.sh

msg_warn "Installing microk8s on ${VM_NODE_PREFIX}$current_counter"
#tranfer_host_dir "${VM_NODE_PREFIX}$current_counter"
#echo "Join command: ${CLUSTER_JOIN_COMMAND}"
multipass exec ${VM_NODE_PREFIX}$current_counter -- $CLUSTER_JOIN_COMMAND

#run_command_on_node "${VM_NODE_PREFIX}$current_counter" "script/__install_microk8s.sh"
#unmount_host_dir ${VM_MAIN_NAME}
#unmount_host_dir ${VM_NODE_PREFIX}$current_counter