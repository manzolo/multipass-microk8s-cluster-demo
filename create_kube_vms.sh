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

echo -e "${BROWN}Check prerequisites${NC}"

#Check prerequisites
check_command_exists "multipass"

#Clean temp files
rm -rf "${HOST_DIR_NAME}/script/_test.sh"


echo -e "${BROWN}== Creating vms cluster${NC}"
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

echo -e "${BROWN}[task 1]== mount host drive with installation scripts ==${NC}"

multipass mount ${HOST_DIR_NAME} k8s-main

#mount drive on nodes
counter=1
while [ $counter -le $instances ]
do
    multipass mount ${HOST_DIR_NAME} k8s-node$counter
    ((counter++))
done

echo -e "${BROWN}[task 2]== installing microk8s on k8s-main ==${NC}"
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"

echo -e "${BROWN}*** installing kuberbetes on worker's node ***${NC}"

counter=1
while [ $counter -le $instances ]
do
    rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
    echo -e "${BROWN}[task 3]== Generate join cluster command k8s-main ==${NC}"
    run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_join_cluster_helper.sh ${HOST_DIR_NAME}"

    echo -e "${BROWN}[task 3]== installing microk8s k8s-node"$counter" ==${NC}"
    run_command_on_node "k8s-node"$counter "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"
    ((counter++))
done

echo -e "${BROWN}[task 4]== Completing microk8s ==${NC}"
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_complete_microk8s.sh ${HOST_DIR_NAME}"

multipass list

IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services go)
echo -e "${GREEN}Try:${NC}"
echo -e "${GRREN}curl http://$IP:$NODEPORT${NC}"

echo "curl http://$IP:$NODEPORT" > "${HOST_DIR_NAME}/script/_test.sh"
chmod +x "${HOST_DIR_NAME}/script/_test.sh"
