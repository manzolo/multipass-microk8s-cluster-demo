#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Include functions (assuming this is defined elsewhere)
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

# Function to create a VM and run commands
create_and_configure_vm() {
    local vm_name=$1
    local ram=$2
    local hdd=$3
    local cpu=$4

    msg_warn "Creating and configuring VM: $vm_name"

    # Create the VM
    if ! multipass launch "22.04" -m $ram -d $hdd -c $cpu -n $vm_name; then
        msg_error "Failed to create VM: $vm_name"
        exit 1
    fi

    add_machine_to_dns $vm_name

    DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
    multipass exec "${vm_name}" -- sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver '"$DNS_IP"'
EOF'

    # --- Install Docker ---
    msg_info "Installing Docker on $vm_name..."
    if ! multipass shell $vm_name  > /dev/null 2>&1 <<EOF
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

    # --- Start Rancher with Docker Compose ---
    msg_info "Starting Rancher on $vm_name using Docker Compose..."

    # Create docker-compose.yml file in the VM
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

    # Run docker-compose
    if ! multipass exec "$vm_name" -- docker compose up -d; then
        msg_error "Failed to start Rancher on $vm_name using Docker Compose."
        exit 1
    fi

    multipass info $vm_name
    echo "Rancher installation completed." # Indicate success within the VM
}

# Create and configure the Rancher VM with a single function call
create_and_configure_vm "${RANCHER_HOSTNAME}" "4Gb" "20Gb" "2"

# Get the IP address of the VM
VM_IP=$(multipass info ${RANCHER_HOSTNAME} | grep IPv4 | awk '{print $2}')

msg_warn "Please wait while Rancher starts up, then navigate to:"
msg_info "https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}"

msg_info "Show access password to rancher first login"
msg_warn "multipass exec ${RANCHER_HOSTNAME} -- docker logs rancher 2>&1 | grep \"Bootstrap Password:\""

echo

msg_info "Show rancher logs"
msg_warn "multipass exec ${RANCHER_HOSTNAME} -- docker logs rancher -f"

echo

msg_warn "Waiting rancher start..."

echo

# Wait for the bootstrap password to appear
timeout_seconds=300  # Timeout di 5 minuti
start_time=$(date +%s)

set +e  # Disabilita set -e temporaneamente

while true; do
  elapsed_time=$(( $(date +%s) - start_time ))
  if [[ "$elapsed_time" -gt "$timeout_seconds" ]]; then
    msg_error "Timeout: Bootstrap password not found within $timeout_seconds seconds."
    exit 1
  fi

  PASSWORD=$(multipass exec ${RANCHER_HOSTNAME} -- docker logs rancher 2>&1 | grep "Bootstrap Password:" | awk '{print $NF}')
  if [[ -n "$PASSWORD" ]]; then
    #msg_warn "$PASSWORD"
    RANCHER_URL="https://${RANCHER_HOSTNAME}.${DNS_SUFFIX}/dashboard/?setup=$PASSWORD"
    
    # Mostra il link all'utente
    msg_info "Use the following link to complete the Rancher setup:"
    msg_warn "$RANCHER_URL"
    break  # Esci dal ciclo quando la password viene trovata
  fi

  sleep 5  # Aspetta 5 secondi prima di riprovare
done

read -n 1 -s -r -p "Press any key to continue..."
echo

#set -e  # Riabilita set -e

# # --- Update /etc/hosts ---
# update_hosts_host() {
#     msg_info "Updating /etc/hosts on the host machine..."
#     if grep -q "${RANCHER_HOSTNAME}.${DNS_SUFFIX}" /etc/hosts; then
#         if sudo sed -i.bak -E "/${RANCHER_HOSTNAME}.${DNS_SUFFIX}/ s/^[0-9.]+/$VM_IP/" /etc/hosts; then
#             msg_info "Updated /etc/hosts. Backup created as /etc/hosts.bak."
#         else
#             msg_error "Error updating /etc/hosts on the host machine."
#         fi
#     else
#         if echo "$VM_IP ${RANCHER_HOSTNAME}.${DNS_SUFFIX}" | sudo tee -a /etc/hosts; then
#             msg_info "Added entry to /etc/hosts on the host machine."
#         else
#             msg_error "Error adding entry to /etc/hosts on the host machine."
#         fi
#     fi
# }

## Update /etc/hosts on the Kubernetes VMs (in parallel)
#multipass list | while read -r line; do
#    if [[ "$line" == *"k8s-"* ]]; then
#        node=$(echo "$line" | awk '{print $1}')
#        node=$(echo "$node" | tr -d '[:space:]')
#
#        echo "Updating /etc/hosts on $node (in background)..."
#
#        # Create a temporary file for the output of this VM
#        output_file=$(mktemp)
#
#        # Run update_hosts_vms in the background, redirecting output
#        update_hosts_vms "$node" > "$output_file" 2>&1 & # Redirect stdout and stderr
#        pids+=($!)
#        output_files+=("$output_file") # Store the output file name
#
#    fi
#done

## Wait for all background processes to finish and display output
#for i in "${!pids[@]}"; do  # Iterate through the indices of the pids array
#    pid=${pids[$i]}
#    wait "$pid"
#    if [[ $? -ne 0 ]]; then
#        msg_error "An error occurred while updating /etc/hosts on one or more VMs."
#        exit 1
#    fi
#
#    # Display the output from the VM in the correct order
#    echo "-------------------- Output for $node --------------------"
#    cat "${output_files[$i]}"
#    rm "${output_files[$i]}" # Clean up the temporary file
#done


# # Ask the user if they want to update /etc/hosts on the host machine
# while true; do
#     read -r -p "Update /etc/hosts on the host machine? (y/n): " choice_hosts
#     case "$choice_hosts" in
#         y|Y)
#             break
#             ;;
#         n|N)
#             echo "Skipping /etc/hosts update on the host machine."
#             break
#             ;;
#         *)
#             echo "Invalid input. Please enter 'y' or 'n'."
#             ;;
#     esac
# done

# if [[ "$choice_hosts" == "y" || "$choice_hosts" == "Y" ]]; then
#     update_hosts_host  # Update the host's /etc/hosts
# fi


# update_hosts_vms() {
#     local vm_name=$1
#     local vm_status=$(multipass info "$vm_name" --format csv | tail -1 | cut -d, -f2)

#     echo "Inside update_hosts_vms for: $vm_name"  # Debugging: Show which VM

#     if [[ "$vm_status" != "Running" ]]; then
#         msg_warn "La VM $vm_name non è attiva. Saltando..."
#         return
#     fi
#     echo "VM $vm_name is running" # Debugging

#     msg_info "Update /etc/hosts on $vm_name..."

#     # Use the Rancher VM's IP ($VM_IP) for ALL Kubernetes nodes
#     multipass exec $vm_name -- sudo bash -c 'grep -q "${RANCHER_HOSTNAME}.${DNS_SUFFIX}" /etc/hosts && sed -i.bak -E "/${RANCHER_HOSTNAME}.${DNS_SUFFIX}/ s/^[0-9.]+/'"$VM_IP"'/" /etc/hosts || echo "'"$VM_IP"' ${RANCHER_HOSTNAME}.${DNS_SUFFIX}" >> /etc/hosts'

#     msg_info "/etc/hosts contents on $vm_name:"
#     multipass exec "$vm_name" -- cat /etc/hosts
# }