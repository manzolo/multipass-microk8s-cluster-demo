#!/bin/bash

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

# Function to clone a VM
clone_vm() {
    local vm_src=$VM_MAIN_NAME
    local vm_dst=$1

    msg_warn "Clone VM: $vm_src"
    if ! multipass clone $vm_src -n $vm_dst; then
        msg_error "Failed to clone VM: $vm_src"
        exit 1
    fi
    multipass info $vm_dst
}

# Function to mount host directory
mount_host_dir() {
    local vm_name=$1

    msg_warn "Mounting host directory to $vm_name"
    if ! multipass mount ${HOST_DIR_NAME} $vm_name; then
        msg_error "Failed to mount directory to $vm_name"
        exit 1
    fi
}

# Include le funzioni
source $(dirname $0)/../script/__functions.sh

# Imposta le variabili di ambiente predefinite se non sono state fornite
HOST_DIR_NAME=${PWD}

# Controlla i prerequisiti
msg_warn "Checking prerequisites..."
check_command_exists "multipass" || { msg_error "Multipass is not installed or cannot be found. Exiting."; exit 1; }

# Pulisce i file temporanei
rm -rf "${HOST_DIR_NAME}/script/_test.sh"

# Trova il numero massimo di istanze k8s-nodeX
max_node_num=$(multipass list | grep k8s-node | awk '{print $1}' | sed 's/k8s-node//' | sort -n | tail -1)

# Avvia una nuova istanza incrementando il numero massimo
if [ -z "$max_node_num" ]; then
    counter=1
else
    ((counter=max_node_num+1))
fi

mount_host_dir $VM_MAIN_NAME
multipass stop $VM_MAIN_NAME

# Create node VMs
clone_vm "k8s-node$counter"
multipass start "k8s-node$counter"

multipass start $VM_MAIN_NAME

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready; do
    sleep 10
done

rm -rf script/_join_node.sh
msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
run_command_on_node $VM_MAIN_NAME "script/_join_cluster_helper.sh"

msg_warn "Installing microk8s on k8s-node$counter"
run_command_on_node "k8s-node$counter" "script/_install_microk8s.sh"

multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
multipass umount "k8s-node$counter:$(multipass info "k8s-node$counter" | grep Mounts | awk '{print $4}')"

# Visualizza l'indirizzo IP e la porta del servizio
multipass list | grep "k8s-"
