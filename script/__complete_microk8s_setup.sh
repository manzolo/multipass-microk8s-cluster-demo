#!/bin/bash

wait_for_microk8s_ready "$VM_MAIN_NAME"

msg_info "=== Task 3: Completing microk8s setup ==="
#mount_host_dir $VM_MAIN_NAME
multipass transfer script/__rollout_pods.sh $VM_MAIN_NAME:/home/ubuntu/rollout_pods.sh
multipass transfer -r config $VM_MAIN_NAME:/home/ubuntu/microk8s_demo_config

# Esegui lo script
multipass exec $VM_MAIN_NAME -- /home/ubuntu/rollout_pods.sh

multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/rollout_pods.sh
#multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/microk8s_demo_config

#unmount_host_dir $VM_MAIN_NAME

