#!/bin/bash

# Copia il file sulla VM
msg_info "=== Task 1: ${VM_MAIN_NAME} Setup ==="
multipass transfer script/__install_microk8s.sh $VM_MAIN_NAME:/home/ubuntu/install_microk8s.sh
# Esegui lo script
multipass exec $VM_MAIN_NAME -- /home/ubuntu/install_microk8s.sh

multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/install_microk8s.sh

multipass stop $VM_MAIN_NAME