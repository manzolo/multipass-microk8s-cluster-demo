#!/bin/bash
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
run_command_on_node () {
    node_name=$1
    command=$2
    multipass exec -v ${node_name} -- ${command}
}

rm -rf "${HOST_DIR_NAME}/script/_test.sh"

echo "== Creating vms cluster"
multipass launch -m $mainRam -d $mainHddGb -c $mainCpu -n k8s-main
counter=1
while [ $counter -le $instances ]
do
multipass launch -m $nodeRam -d $nodeHddGb -c $nodeCpu -n k8s-node$counter
((counter++))
done

HOST_DIR_NAME=${PWD}

multipass list | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var}' > ${HOST_DIR_NAME}/config/hosts

echo "[task 1]== mount host drive with installation scripts =="

multipass mount ${HOST_DIR_NAME} k8s-main

counter=1
while [ $counter -le $instances ]
do
multipass mount ${HOST_DIR_NAME} k8s-node$counter
((counter++))
done

echo "[task 2]== installing microk8s k8s-main =="
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"

echo "*** installing kuberbetes on worker's node ***"

counter=1
while [ $counter -le $instances ]
do
rm -rf ${HOST_DIR_NAME}/script/_join_node.sh
echo "[task 3]== Generate join cluster command k8s-main =="
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_join_cluster_helper.sh ${HOST_DIR_NAME}"

echo "[task 3]== installing microk8s k8s-node"$counter" =="
run_command_on_node "k8s-node"$counter "${HOST_DIR_NAME}/script/_install_microk8s.sh ${HOST_DIR_NAME}"
((counter++))
done

echo "[task 4]== Completing microk8s =="
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/script/_complete_microk8s.sh ${HOST_DIR_NAME}"

multipass list

IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services go)
echo "Try:"
echo "curl http://$IP:$NODEPORT"

echo "curl http://$IP:$NODEPORT" > "${HOST_DIR_NAME}/script/_test.sh"
chmod +x "${HOST_DIR_NAME}/script/_test.sh"
