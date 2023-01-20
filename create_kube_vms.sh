#!/bin/bash

HOST_DIR_NAME=${PWD}

#------------------- Env vars ---------------------------------------------
#Number of nodes
instances="${1:-2}"
#Number of Cpu for main VM
mainCpu=2
#GB of RAM for main VM
mainRam=2Gb
#GB of HDD for main VM
mainHddGb=10Gb
#Number of Cpu for node VM
nodeCpu=1
#GB of RAM for node VM
nodeRam=1Gb
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


msg_warn "Creating vms cluster"
multipass launch -m $mainRam -d $mainHddGb -c $mainCpu -n k8s-main

#Create vms
counter=1
while [ $counter -le $instances ]
do
    multipass launch -m $nodeRam -d $nodeHddGb -c $nodeCpu -n k8s-node$counter
    ((counter++))
done

#Create host file
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var}' > ${HOST_DIR_NAME}/config/hosts

msg_info "[Task 1]"
msg_warn "Mount host drive with installation scripts"

multipass mount ${HOST_DIR_NAME} k8s-main

#mount drive on nodes
counter=1
while [ $counter -le $instances ]
do
    multipass mount ${HOST_DIR_NAME} k8s-node$counter
    ((counter++))
done

msg_info "[Task 2]"
msg_warn "Installing microk8s on k8s-main"
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"

msg_info "[Task 3]"
msg_info "*** Installing kuberbetes on worker's node ***"

counter=1
while [ $counter -le $instances ]
do
    rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
    msg_warn "Generate join cluster command k8s-main"
    run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_join_cluster_helper.sh ${HOST_DIR_NAME}"

    msg_warn "installing microk8s k8s-node"$counter""
    run_command_on_node "k8s-node"$counter "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"
    ((counter++))
done

msg_info "[Task 4]"
msg_warn "Completing microk8s"
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_complete_microk8s.sh ${HOST_DIR_NAME}"

multipass list

IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services go)
msg_warn "Try:"
msg_info "curl -s http://$IP:$NODEPORT"

echo "curl -s http://$IP:$NODEPORT" > "${HOST_DIR_NAME}/script/_test.sh"
chmod +x "${HOST_DIR_NAME}/script/_test.sh"
