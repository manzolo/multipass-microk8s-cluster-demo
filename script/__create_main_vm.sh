#!/bin/bash

# Create main VM
create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"
mount_host_dir $VM_MAIN_NAME

add_machine_to_dns $VM_MAIN_NAME

msg_info "Configuring DNS resolver on $VM_MAIN_NAME to use $DNS_VM_NAME"
DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
multipass exec "$VM_MAIN_NAME" -- sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver '"$DNS_IP"'
EOF'
