# Create node VMs
for ((counter=1; counter<=instances; counter++)); do
    clone_vm "${VM_NODE_PREFIX}$counter"
    multipass start "${VM_NODE_PREFIX}$counter"
    add_machine_to_dns "${VM_NODE_PREFIX}$counter"

    msg_warn "Configuring DNS resolver on "${VM_NODE_PREFIX}$counter" to use $DNS_VM_NAME"

    multipass info "${VM_NODE_PREFIX}$counter"
done

multipass start $VM_MAIN_NAME

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready > /dev/null 2>&1; do
    sleep 10
done