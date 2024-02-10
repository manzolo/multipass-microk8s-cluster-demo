#!/bin/bash

# Imposta le variabili di ambiente predefinite se non sono state fornite
HOST_DIR_NAME=${PWD}
NODE_TYPE=${1:-worker}
NODE_CPU=${2:-2}
NODE_RAM=${3:-2Gb}
NODE_HDD_GB=${4:-10Gb}

# Include le funzioni
source $(dirname $0)/script/__functions.sh

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
multipass launch -m $NODE_RAM -d $NODE_HDD_GB -c $NODE_CPU -n k8s-node$counter || { msg_error "Failed to launch a new instance. Exiting."; exit 1; }

# Crea il file degli hosts
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var}' > ${HOST_DIR_NAME}/config/hosts || { msg_error "Failed to create hosts file. Exiting."; exit 1; }

# Monta il disco host sulla nuova istanza
msg_info "Mounting host drive with installation scripts"
multipass mount ${HOST_DIR_NAME} k8s-node$counter || { msg_error "Failed to mount host drive on the new instance. Exiting."; exit 1; }

# Esegui l'installazione di Kubernetes sul nodo worker
msg_info "Installing Kubernetes on the worker node"
rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
msg_warn "Generating join cluster command for k8s-main"
if ! run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_join_cluster_helper.sh ${HOST_DIR_NAME} ${NODE_TYPE}"; then
    msg_error "Failed to generate join cluster command. Exiting."
    exit 1
fi

msg_warn "Installing MicroK8s on k8s-node$counter"
if ! run_command_on_node "k8s-node$counter" "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"; then
    msg_error "Failed to install MicroK8s on k8s-node$counter. Exiting."
    exit 1
fi

# Visualizza l'indirizzo IP e la porta del servizio
multipass list
IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go)
msg_warn "Try:"
msg_info "curl -s http://$IP:$NODEPORT"
