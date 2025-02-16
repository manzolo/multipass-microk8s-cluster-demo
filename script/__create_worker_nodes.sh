# Create node VMs
for ((counter=1; counter<=instances; counter++)); do
    clone_vm "${VM_NODE_PREFIX}$counter"
    multipass start "${VM_NODE_PREFIX}$counter"
    add_machine_to_dns "${VM_NODE_PREFIX}$counter"

    msg_info "Configuring DNS resolver on "${VM_NODE_PREFIX}$counter" to use $DNS_VM_NAME"
    DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
    multipass exec "${VM_NODE_PREFIX}$counter" -- sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver '"$DNS_IP"'
EOF'
    multipass info "${VM_NODE_PREFIX}$counter"
done

multipass start $VM_MAIN_NAME

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready; do
    sleep 10
done