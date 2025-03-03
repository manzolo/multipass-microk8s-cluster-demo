#!/bin/bash

set -e

# Function to create a VM and run commands
create_and_configure_rancher_vm() {
    local VM_NAME=$1
    local RAM=$2
    local HDD=$3
    local CPU=$4

    msg_warn "Creating and configuring VM: $VM_NAME"

    # Create the VM
    if ! multipass launch "22.04" -m "$RAM" -d "$HDD" -c "$CPU" -n "$VM_NAME"; then
        msg_error "Failed to create VM: $VM_NAME"
        exit 1
    fi

    add_machine_to_dns "$VM_NAME"
    restart_dns_service
    configure_rancher_dns_resolution "$VM_NAME"
    install_docker "$VM_NAME"
    start_rancher "$VM_NAME"
    show_rancher_info "$VM_NAME"
    add_motd_rancher "$VM_NAME"
}

# Function to configure DNS resolution
configure_rancher_dns_resolution() {
    local VM_NAME=$1
    local DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
    multipass exec "$VM_NAME" -- sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver '"$DNS_IP"'
EOF'
}

# Function to start Rancher
start_rancher() {
    local VM_NAME=$1
    msg_info "Starting Rancher on $VM_NAME using Docker Compose..."
    multipass exec "$VM_NAME" -- bash -c 'cat > docker-compose.yml <<EOF
services:
  rancher:
    image: rancher/rancher:'"$RANCHER_VERSION"'
    container_name: rancher
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    privileged: true
    volumes:
      - rancher_data:/var/lib/rancher

volumes:
  rancher_data:
EOF'

    if ! multipass exec "$VM_NAME" -- docker compose up -d; then
        msg_error "Failed to start Rancher on $VM_NAME using Docker Compose."
        exit 1
    fi
}

# Function to show Rancher info
show_rancher_info() {
    local VM_NAME=$1
    multipass info "$VM_NAME"
    echo "Rancher installation completed."
}


# Function to wait for Rancher bootstrap password
wait_for_rancher_password() {
    msg_warn "Waiting rancher start..."
    local timeout_seconds=300
    local start_time=$(date +%s)

    set +e

    while true; do
        local elapsed_time=$(( $(date +%s) - start_time ))
        if [[ "$elapsed_time" -gt "$timeout_seconds" ]]; then
            msg_error "Timeout: Bootstrap password not found within $timeout_seconds seconds."
            exit 1
        fi

        local PASSWORD=$(multipass exec "${RANCHER_HOSTNAME}" -- docker logs rancher 2>&1 | grep "Bootstrap Password:" | awk '{print $NF}')
        if [[ -n "$PASSWORD" ]]; then
            local RANCHER_URL="https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}/dashboard/?setup=$PASSWORD"
            msg_info "Use the following link to complete the Rancher setup:"
            vm_ip=$(get_vm_ip "${RANCHER_HOSTNAME}")
            msg_warn "https://${vm_ip}/dashboard/?setup=${PASSWORD}"
            msg_warn "$RANCHER_URL"
            break
        fi

        sleep 5
    done
    set -e
}

function create_rancher() {
    # Main script execution
    create_and_configure_rancher_vm "${RANCHER_HOSTNAME}" "4Gb" "20Gb" "2"
    wait_for_rancher_password
    press_any_key
}

function destroy_rancher() {
    remove_machine_from_dns $RANCHER_HOSTNAME
    restart_dns_service

    multipass stop --force ${RANCHER_HOSTNAME} > /dev/null 2>&1
    multipass delete --purge ${RANCHER_HOSTNAME} > /dev/null 2>&1
    multipass purge > /dev/null 2>&1
}