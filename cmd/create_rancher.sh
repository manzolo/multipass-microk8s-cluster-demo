#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Include functions (assuming this is defined elsewhere)
source $(dirname $0)/../script/__functions.sh

# Function to create a VM and run commands
create_and_configure_vm() {
    local vm_name=$1
    local ram=$2
    local hdd=$3
    local cpu=$4

    msg_warn "Creating and configuring VM: $vm_name"

    # Create the VM
    if ! multipass launch -m $ram -d $hdd -c $cpu -n $vm_name; then
        msg_error "Failed to create VM: $vm_name"
        exit 1
    fi

    # --- Install Docker ---
    msg_info "Installing Docker on $vm_name..."
    if ! multipass shell $vm_name <<EOF
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

    # --- Start Rancher ---
    msg_info "Starting Rancher on $vm_name..."
    if ! multipass shell $vm_name <<EOF
#!/bin/bash
set -e

# Start Rancher
docker run -d \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  --privileged \
  --name rancher \
  rancher/rancher:v2.9.2

# Check if Rancher container started successfully
if ! docker ps | grep rancher; then
    echo "ERROR: Rancher container failed to start."
    exit 1
fi
exit 0
EOF
    then
        msg_error "Failed to start Rancher on $vm_name. Check the VM's console for details."
        #multipass exec rancher -- docker logs rancher 2>&1  # Show logs for debugging
        exit 1
    fi

    multipass info $vm_name
    echo "Rancher installation completed." # Indicate success within the VM
}

# Create and configure the Rancher VM with a single function call
create_and_configure_vm "rancher" "4Gb" "20Gb" "1"

# Get the IP address of the VM
VM_IP=$(multipass info rancher | grep IPv4 | awk '{print $2}')

msg_warn "Please wait while Rancher starts up, then navigate to:"
msg_info "https://rancher.loc"

msg_info "Show access password to rancher first login"
msg_warn "multipass exec rancher -- docker logs rancher 2>&1 | grep \"Bootstrap Password:\""

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

  PASSWORD=$(multipass exec rancher -- docker logs rancher 2>&1 | grep "Bootstrap Password:" | awk '{print $NF}')
  if [[ -n "$PASSWORD" ]]; then
    #msg_warn "$PASSWORD"
    RANCHER_URL="https://rancher.loc/dashboard/?setup=$PASSWORD"
    
    # Mostra il link all'utente
    msg_info "Use the following link to complete the Rancher setup:"
    msg_warn "$RANCHER_URL"
    break  # Esci dal ciclo quando la password viene trovata
  fi

  sleep 5  # Aspetta 5 secondi prima di riprovare
done

set -e  # Riabilita set -e

# Ask the user if they want to update /etc/hosts automatically
while true; do
    read -r -p "Update /etc/hosts automatically? (y/n): " choice_hosts
    case "$choice_hosts" in
        y|Y)
            break
            ;;
        n|N)
            echo "Skipping /etc/hosts update."
            break
            ;;
        *)
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
done

# update /etc/hosts on VM k8s-main
multipass exec k8s-main -- sudo sed -i.bak -E "/rancher.loc/ s/^[0-9.]+/$VM_IP/" /etc/hosts

if [[ "$choice_hosts" == "y" || "$choice_hosts" == "Y" ]]; then
    # Check if the line already exists and update or add it
    if grep -q "rancher.loc" /etc/hosts; then
        msg_info "Updating /etc/hosts..."
        if sudo sed -i.bak -E "/rancher.loc/ s/^[0-9.]+/$VM_IP/" /etc/hosts; then
            msg_info "Updated /etc/hosts. Backup created as /etc/hosts.bak."
        else
            msg_error "Error updating /etc/hosts."
        fi
    else
        msg_info "Adding entry to /etc/hosts..."
        if echo "$VM_IP rancher.loc" | sudo tee -a /etc/hosts; then
            msg_info "Added entry to /etc/hosts."
        else
            msg_error "Error adding entry to /etc/hosts."
        fi
    fi
fi
