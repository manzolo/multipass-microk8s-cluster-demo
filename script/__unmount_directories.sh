#!/bin/bash

msg_warn "Unmounting directories..."
multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
for ((counter=1; counter<=instances; counter++)); do
    multipass umount "${VM_NODE_PREFIX}$counter:$(multipass info "${VM_NODE_PREFIX}$counter" | grep Mounts | awk '{print $4}')"
done