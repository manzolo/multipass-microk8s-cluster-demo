#!/bin/bash

msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready  > /dev/null 2>&1; do
    sleep 10
done

msg_info "=== Task 3: Completing microk8s setup ==="
run_command_on_node $VM_MAIN_NAME "script/__rollout_pods.sh"