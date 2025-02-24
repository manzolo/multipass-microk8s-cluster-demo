#!/bin/bash

wait_for_microk8s_ready "$VM_MAIN_NAME"

msg_info "=== Task 3: Completing microk8s setup ==="
mount_host_dir $VM_MAIN_NAME
run_command_on_node $VM_MAIN_NAME "script/__rollout_pods.sh"
unmount_host_dir $VM_MAIN_NAME

