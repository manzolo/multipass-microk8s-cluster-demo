#!/bin/bash

HOST_DIR_NAME=${PWD}

#------------------- Env vars ---------------------------------------------
#Number of nodes
instances="${1:-2}"
#Number of Cpu for main VM
mainCpu=${2:-2}
#GB of RAM for main VM
mainRam=${3:-2Gb}
#GB of HDD for main VM
mainHddGb=${4:-10Gb}
#Number of Cpu for node VM
nodeCpu=${5:-1}
#GB of RAM for node VM
nodeRam=${6:-2Gb}
#GB of HDD for main VM
nodeHddGb=${7:-10Gb}
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

multipass info k8s-main

#Create vms
counter=1
while [ $counter -le $instances ]
do
    multipass launch -m $nodeRam -d $nodeHddGb -c $nodeCpu -n k8s-node$counter
    multipass info k8s-node$counter
    #multipass stop k8s-node$counter
    #multipass start k8s-node$counter
    ((counter++))
done

#Create host file
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var".loc"}' > config/hosts

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
run_command_on_node "k8s-main" "script/_install_microk8s.sh"

msg_info "[Task 3]"
msg_info "*** Installing kuberbetes on worker's node ***"

counter=1
while [ $counter -le $instances ]
do
    rm -rf script/_join_node.sh
    msg_warn "Generate join cluster command k8s-main"
    run_command_on_node "k8s-main" "script/_join_cluster_helper.sh"

    msg_warn "installing microk8s k8s-node"$counter""
    run_command_on_node "k8s-node"$counter "script/_install_microk8s.sh"
    ((counter++))
done

msg_warn "Ready for deployment..."
sleep 60

msg_info "[Task 4]"
msg_warn "Completing microk8s"
run_command_on_node "k8s-main" "script/_complete_microk8s.sh"
msg_warn "Umount k8s-main:$(multipass info k8s-main | grep Mounts | awk '{print $4}')"
multipass umount k8s-main:$(multipass info k8s-main | grep Mounts | awk '{print $4}')
counter=1
while [ $counter -le $instances ]
do
    msg_warn "Umount "k8s-node"$counter -> $(multipass info "k8s-node$counter" | grep Mounts | awk '{print $4}')"
    multipass umount "k8s-node$counter:$(multipass info "k8s-node$counter" | grep Mounts | awk '{print $4}')"
    ((counter++))
done

multipass list

IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT_GO=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
NODEPORT_PHP=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)
msg_warn "Try golang service:"
msg_info "curl -s http://$IP:$NODEPORT_GO"

echo "curl -s http://$IP:$NODEPORT_GO" > "script/_test.sh"
chmod +x "script/_test.sh"
script/_test.sh

echo

msg_warn "Try php response on browser:"
msg_info "http://$IP:$NODEPORT_PHP"
