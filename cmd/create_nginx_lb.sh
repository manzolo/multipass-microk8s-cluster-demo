#!/bin/bash
set -e

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

HOST_DIR_NAME=${PWD}

# Default values (fallback if not in .env) - These are now overridden by .env
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}" # Use .env var if set, else default

# Include functions
source $(dirname $0)/../script/__functions.sh

# Definisci K8S_HOSTS includendo solo quelle macchine che hanno un IP valido
K8S_HOSTS=$(multipass list \
  | grep "k8s-" \
  | grep -E -v "Name|\-\-" \
  | awk '{ printf "%s\t%s.loc\n", $3, $1 }')

# Verifica se almeno una VM NON ha un IP (controlla "-" o "--" o campo vuoto)
missing_ips=$(multipass list \
  | grep "k8s-" \
  | grep -v "Name" \
  | awk '$3 == "-" || $3 == "--" || $3 == ""')

if [ -n "$missing_ips" ]; then
  #multipass list
  echo "Errore: almeno una VM non ha un IP:" >&2
  echo "$missing_ips" >&2
  exit 1
fi

# Launch a new VM with the specified requirements
multipass launch $DEFAULT_UBUNTU_VERSION -m 2Gb -d 5Gb -c 1 -n nginx-cluster-balancer

# Mount a directory from the host into the VM
multipass mount ${HOST_DIR_NAME}/config nginx-cluster-balancer:/mnt/host-config

# Access the newly created VM
multipass shell nginx-cluster-balancer <<EOF

# Update the repositories
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Copy the Nginx configuration file from the mounted directory
sudo cp /mnt/host-config/nginx_lb.conf /etc/nginx/sites-available/cluster-balancer

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/cluster-balancer /etc/nginx/sites-enabled/

echo "$K8S_HOSTS" | sudo tee -a /etc/hosts

# Verify the correctness of the Nginx configuration
sudo nginx -t

# Reload Nginx to apply the new configuration
sudo systemctl reload nginx

sudo systemctl enable nginx

EOF

# Unmount the directory from the VM
multipass umount nginx-cluster-balancer:/mnt/host-config

# List the VMs
multipass list

# Get the IP address of the VM
VM_IP=$(multipass info nginx-cluster-balancer | grep IPv4 | awk '{print $2}')

echo
echo

# Print instructions to add to the host's /etc/hosts file
msg_warn "Add the following line to the /etc/hosts file of the host:"
msg_warn "$VM_IP nginx-cluster-balancer demo-go.loc demo-php.loc"
echo

# Ask the user if they want to execute the command
while true; do
    read -r -p "Do you want to execute this command now? (y/n): " choice
    case "$choice" in
        y|Y)
            break  # Exit the loop if the user says yes
            ;;
        n|N)
            echo "Skipping /etc/hosts update."
            exit 0 # Return 0 to indicate that the operation was skipped, not an error.
            ;;
        *)
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
done


# Check if the line already exists and update or add it
if grep -q "nginx-cluster-balancer demo-go.loc demo-php.loc" /etc/hosts; then
    msg_info "Updating /etc/hosts..."
    if sudo sed -i.bak -E "/nginx-cluster-balancer demo-go.loc demo-php.loc/ s/^[0-9.]+/$VM_IP/" /etc/hosts; then
        msg_info "Updated /etc/hosts. Backup created as /etc/hosts.bak."
    else
        msg_error "Error updating /etc/hosts."
        exit 1 # 1 to indicate an error
    fi
else
    msg_info "Adding entry to /etc/hosts..."
    if echo "$VM_IP nginx-cluster-balancer demo-go.loc demo-php.loc" | sudo tee -a /etc/hosts; then
        msg_info "Added entry to /etc/hosts."
    else
        msg_error "Error adding entry to /etc/hosts."
        exit 1 # 1 to indicate an error
    fi
fi