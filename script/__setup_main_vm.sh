#!/bin/bash

msg_info "=== Task 1: ${VM_MAIN_NAME} Setup ==="
run_command_on_node $VM_MAIN_NAME "script/__install_microk8s.sh"

multipass stop $VM_MAIN_NAME

