#!/bin/bash

HOST_DIR_NAME=${PWD}

#------------------- Env vars ---------------------------------------------
#Number of Cpu for node VM
nodeCpu=2
#GB of RAM for node VM
nodeRam=2Gb
#GB of HDD for main VM
nodeHddGb=10Gb
#--------------------------------------------------------------------------

#Include functions
source $(dirname $0)/script/__functions.sh

msg_warn "Check prerequisites..."

#Check prerequisites
check_command_exists "multipass"

#Clean temp files
rm -rf "${HOST_DIR_NAME}/script/_test.sh"


# Trova il numero massimo usato per le istanze k8s-nodeX
max_node_num=$(multipass list | grep k8s-node | awk '{print $1}' | sed 's/k8s-node//' | sort -n | tail -1)

# Assicurati che il contatore inizi da un numero successivo al massimo trovato
if [ -z "$max_node_num" ]; then
    counter=1
else
    ((counter=max_node_num+1))
fi
multipass launch -m $nodeRam -d $nodeHddGb -c $nodeCpu -n k8s-node$counter

#Create host file
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var}' > ${HOST_DIR_NAME}/config/hosts

msg_info "[Task 1]"
msg_warn "Mount host drive with installation scripts"

#multipass mount ${HOST_DIR_NAME} k8s-main
multipass mount ${HOST_DIR_NAME} k8s-node$counter

msg_info "[Task 2]"
msg_info "*** Installing kuberbetes on worker's node ***"

rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
msg_warn "Generate join cluster command k8s-main"
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_join_cluster_helper.sh ${HOST_DIR_NAME}"

msg_warn "installing microk8s k8s-node"$counter""
run_command_on_node "k8s-node"$counter "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"

multipass list

IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go)
msg_warn "Try:"
msg_info "curl -s http://$IP:$NODEPORT"

