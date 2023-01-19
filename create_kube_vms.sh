#!/bin/bash
run_command_on_node () {
    node_name=$1
    command=$2
    multipass exec -v ${node_name} -- ${command}
}
echo "== Creating vms cluster"
multipass launch -m 4Gb -d 10G -c 2 -n k8s-main
multipass launch -m 2Gb -d 10G -c 1 -n k8s-node1
multipass launch -m 2Gb -d 10G -c 1 -n k8s-node2
HOST_DIR_NAME=${PWD}

echo "[task 1]== mount host drive with installation scripts =="

multipass mount ${HOST_DIR_NAME} k8s-main

multipass mount ${HOST_DIR_NAME} k8s-node1

multipass mount ${HOST_DIR_NAME} k8s-node2

echo "[task 2]== installing microk8s k8s-main =="
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/_install_microk8s.sh ${HOST_DIR_NAME}"

echo "*** installing kuberbetes on worker's node ***"
echo "[task 3]== installing microk8s k8s-node1 =="
run_command_on_node "k8s-node1" "${HOST_DIR_NAME}/_install_microk8s.sh ${HOST_DIR_NAME}"

echo "[task 4]== installing microk8s k8s-node2 =="
run_command_on_node "k8s-node2" "${HOST_DIR_NAME}/_install_microk8s.sh ${HOST_DIR_NAME}"

echo "[task 3]== Completing microk8s =="
run_command_on_node "k8s-main" "${HOST_DIR_NAME}/_complete_microk8s.sh ${HOST_DIR_NAME}"

multipass list