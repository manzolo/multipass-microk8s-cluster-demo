#!/bin/bash
set -e

HOST_DIR_NAME=$(pwd)

# Include functions (assuming this is defined elsewhere)
source "$(dirname "$0")/../script/__functions.sh"

# Load default values and environment variables
source "$(dirname "$0")/../script/__load_env.sh"

# Function to create a VM and run commands
create_and_configure_vm() {
    local vm_name=$1
    local ram=$2
    local hdd=$3
    local cpu=$4

    msg_warn "Creating and configuring VM: $vm_name"

    # Create the VM
    if ! multipass launch "22.04" -m "$ram" -d "$hdd" -c "$cpu" -n "$vm_name"; then
        msg_error "Failed to create VM: $vm_name"
        exit 1
    fi

    add_machine_to_dns "$vm_name"
    configure_dns_resolution "$vm_name"
    install_docker "$vm_name"
    start_rancher "$vm_name"
    show_rancher_info "$vm_name"
    add_motd_rancher "$vm_name"
}

# Function to configure DNS resolution
configure_dns_resolution() {
    local vm_name=$1
    local DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
    multipass exec "$vm_name" -- sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver '"$DNS_IP"'
EOF'
}

# Function to install Docker
install_docker() {
    local vm_name=$1
    msg_info "Installing Docker on $vm_name..."
    if ! multipass shell "$vm_name" > /dev/null 2>&1 <<EOF
#!/bin/bash
set -e

# Remove old Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y \$pkg
done

# Add Docker's official GPG key
sudo apt update -qq
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
echo \
  "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu || true # Ignore if group doesn't exist yet
sudo systemctl unmask docker
sudo systemctl enable docker
sudo systemctl start docker
EOF
    then
        msg_error "Failed to enable Docker on $vm_name."
        exit 1
    fi
}

# Function to start Rancher
start_rancher() {
    local vm_name=$1
    msg_info "Starting Rancher on $vm_name using Docker Compose..."
    multipass exec "$vm_name" -- bash -c 'cat > docker-compose.yml <<EOF
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

    if ! multipass exec "$vm_name" -- docker compose up -d; then
        msg_error "Failed to start Rancher on $vm_name using Docker Compose."
        exit 1
    fi
}

# Function to show Rancher info
show_rancher_info() {
    local vm_name=$1
    multipass info "$vm_name"
    echo "Rancher installation completed."
}

# Function to add MOTD for Rancher
add_motd_rancher() {
    local vm_name=$1
    local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Rancher Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 3)$(tput bold)🔄 Restart Rancher:$(tput sgr0)
$(tput setaf 3)docker compose down && docker compose rm -f && docker compose up -d$(tput sgr0)

$(tput setaf 6)$(tput bold)👀 Check Rancher logs:$(tput sgr0)
$(tput setaf 6)docker logs rancher -f $(tput sgr0)

$(tput setaf 5)$(tput bold)🔑 Show rancher bootstrap password:$(tput sgr0)
$(tput setaf 5)docker logs rancher 2>&1 | grep "Bootstrap Password:"$(tput sgr0)

Rancher homepage:
https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}

Use the following link to complete the Rancher setup:
https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}/dashboard/?setup=BOOTSTRAP_PASSWORD_HERE
EOF
    )

    msg_warn "Add ${vm_name} MOTD"
    multipass exec "$vm_name" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${vm_name}:"
echo "$MOTD_COMMANDS"
EOF
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
            msg_warn "$RANCHER_URL"
            break
        fi

        sleep 5
    done
    set -e
}

# Main script execution
create_and_configure_vm "${RANCHER_HOSTNAME}" "4Gb" "20Gb" "2"
wait_for_rancher_password
press_any_key