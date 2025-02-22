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

# Trova tutti i numeri dei nodi esistenti
existing_nodes=$(multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}' | sed "s/${VM_NODE_PREFIX}//" | sort -n)

# Trova il primo numero disponibile
available_num=1
for num in $existing_nodes; do
    if [ "$num" -eq "$available_num" ]; then
        ((available_num++))
    else
        break
    fi
done

# Se non ci sono numeri disponibili, incrementa il numero massimo
if [ -z "$existing_nodes" ]; then
    counter=1
else
    max_node_num=$(echo "$existing_nodes" | tail -1)
    if [ "$available_num" -le "$max_node_num" ]; then
        counter=$available_num
    else
        ((counter=max_node_num+1))
    fi
fi

mount_host_dir $VM_MAIN_NAME
multipass stop $VM_MAIN_NAME

# Create node VMs
clone_vm "${VM_NODE_PREFIX}$counter"
multipass start "${VM_NODE_PREFIX}$counter"

add_machine_to_dns "${VM_NODE_PREFIX}$counter"

multipass info "${VM_NODE_PREFIX}$counter"
multipass start $VM_MAIN_NAME

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready > /dev/null 2>&1; do
    sleep 10
done

rm -rf ./_join_node.sh
msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
run_command_on_node $VM_MAIN_NAME "script/__join_cluster_helper.sh"

msg_warn "Installing microk8s on ${VM_NODE_PREFIX}$counter"
run_command_on_node "${VM_NODE_PREFIX}$counter" "script/__install_microk8s.sh"

multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
multipass umount "${VM_NODE_PREFIX}$counter:$(multipass info "${VM_NODE_PREFIX}$counter" | grep Mounts | awk '{print $4}')"

# Visualizza l'indirizzo IP e la porta del servizio
multipass list | grep "k8s-"
