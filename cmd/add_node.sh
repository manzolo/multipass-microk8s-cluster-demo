#!/bin/bash

# Include le funzioni
source $(dirname $0)/../script/__functions.sh

# Imposta le variabili di ambiente predefinite se non sono state fornite
HOST_DIR_NAME=${PWD}

# Controlla i prerequisiti
msg_warn "Checking prerequisites..."
check_command_exists "multipass" || { msg_error "Multipass is not installed or cannot be found. Exiting."; exit 1; }

# Pulisce i file temporanei
rm -rf "${HOST_DIR_NAME}/script/_test.sh"

# Trova il numero massimo di istanze ${VM_NODE_PREFIX}X
max_node_num=$(multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}' | sed "s/${VM_NODE_PREFIX}//" | sort -n | tail -1)

# Avvia una nuova istanza incrementando il numero massimo
if [ -z "$max_node_num" ]; then
    counter=1
else
    ((counter=max_node_num+1))
fi

mount_host_dir $VM_MAIN_NAME
multipass stop $VM_MAIN_NAME

# Create node VMs
clone_vm "${VM_NODE_PREFIX}$counter"
multipass start "${VM_NODE_PREFIX}$counter"
multipass info "${VM_NODE_PREFIX}$counter"
multipass start $VM_MAIN_NAME

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready; do
    sleep 10
done

rm -rf script/_join_node.sh
msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
run_command_on_node $VM_MAIN_NAME "script/_join_cluster_helper.sh"

msg_warn "Installing microk8s on ${VM_NODE_PREFIX}$counter"
run_command_on_node "${VM_NODE_PREFIX}$counter" "script/_install_microk8s.sh"

multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
multipass umount "${VM_NODE_PREFIX}$counter:$(multipass info "${VM_NODE_PREFIX}$counter" | grep Mounts | awk '{print $4}')"

# Visualizza l'indirizzo IP e la porta del servizio
multipass list | grep "k8s-"
