#!/bin/bash

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

# Include le funzioni
source $(dirname $0)/../script/__functions.sh

# Default values (fallback if not in .env) - These are now overridden by .env
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}" # Use .env var if set, else default

# Imposta le variabili di ambiente predefinite se non sono state fornite
HOST_DIR_NAME=${PWD}
VM_MOUNT_DIR="/home/ubuntu/multipass-microk8s-cluster-demo"  # Percorso montato nella VM
NODE_TYPE=${1:-worker}
NODE_CPU=${2:-2}
NODE_RAM=${3:-2Gb}
NODE_HDD_GB=${4:-10Gb}

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

msg_info "Launching a new instance: k8s-node$counter"
multipass launch $DEFAULT_UBUNTU_VERSION -m $NODE_RAM -d $NODE_HDD_GB -c $NODE_CPU -n k8s-node$counter || { msg_error "Failed to launch a new instance. Exiting."; exit 1; }

# Crea il file degli hosts
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var}' > ${HOST_DIR_NAME}/config/hosts || { msg_error "Failed to create hosts file. Exiting."; exit 1; }

# Monta il disco host sulla nuova istanza
msg_info "Mounting host drive with installation scripts"
multipass mount ${HOST_DIR_NAME} k8s-node$counter:${VM_MOUNT_DIR} || { msg_error "Failed to mount host drive on the new instance. Exiting."; exit 1; }
multipass mount ${HOST_DIR_NAME} ${VM_MAIN_NAME}:${VM_MOUNT_DIR} || { msg_error "Failed to mount host drive on ${VM_MAIN_NAME}. Exiting."; exit 1; }

# Esegui l'installazione di Kubernetes sul nodo worker
msg_info "Installing Kubernetes on the worker node"
rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
if ! run_command_on_node "${VM_MAIN_NAME}" "${VM_MOUNT_DIR}/script/_join_cluster_helper.sh ${VM_MOUNT_DIR} ${NODE_TYPE}"; then
    msg_error "Failed to generate join cluster command. Exiting."
    exit 1
fi

msg_warn "Installing MicroK8s on k8s-node$counter"
if ! run_command_on_node "k8s-node$counter" "${VM_MOUNT_DIR}/script/_install_microk8s.sh ${VM_MOUNT_DIR}"; then
    msg_error "Failed to install MicroK8s on k8s-node$counter. Exiting."
    exit 1
fi

multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
multipass umount "k8s-node$counter:$(multipass info "k8s-node$counter" | grep Mounts | awk '{print $4}')"


# Visualizza l'indirizzo IP e la porta del servizio
multipass list
IP=$(multipass info ${VM_MAIN_NAME} | grep IPv4 | awk '{print $2}')
NODEPORT=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
msg_warn "Try:"
msg_info "curl -s http://$IP:$NODEPORT"