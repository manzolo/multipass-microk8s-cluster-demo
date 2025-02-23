#!/bin/bash

msg_info "=== Task 1: ${VM_MAIN_NAME} Setup ==="

mount_host_dir $VM_MAIN_NAME
run_command_on_node $VM_MAIN_NAME "script/__install_microk8s.sh"
unmount_host_dir $VM_MAIN_NAME

multipass stop $VM_MAIN_NAME

