#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

# Default values (fallback if not in .env) - These are now overridden by .env
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}" # Use .env var if set, else default
# Launch a new VM with the specified requirements
multipass launch $DEFAULT_UBUNTU_VERSION -m 2Gb -d 5Gb -c 1 -n $LOAD_BALANCE_HOSTNAME

add_machine_to_dns $LOAD_BALANCE_HOSTNAME

DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
multipass exec "${LOAD_BALANCE_HOSTNAME}" -- sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver '"$DNS_IP"'
EOF'

# Trova tutte le istanze esistenti di ${VM_NODE_PREFIX}X
node_instances=$(multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}')

# Genera il file di configurazione di Nginx
nginx_config="${HOST_DIR_NAME}/config/nginx_lb.conf"

# Sostituisci le variabili d'ambiente nel template
VARIABLES_TO_REPLACE='$VM_MAIN_NAME $VM_NODE_PREFIX'
envsubst "$VARIABLES_TO_REPLACE" < ${HOST_DIR_NAME}/config/nginx_lb.template > "$nginx_config"

# Aggiungi tutte le istanze di k8s-node{n} al file di configurazione
for node in $node_instances; do
  sed -i "/upstream k8s-cluster-go {/a\    server ${node}.${DNS_SUFFIX}:31001;" "$nginx_config"
  sed -i "/upstream k8s-cluster-php {/a\    server ${node}.${DNS_SUFFIX}:31002;" "$nginx_config"
done

# Mount a directory from the host into the VM
multipass mount ${HOST_DIR_NAME}/config $LOAD_BALANCE_HOSTNAME:/mnt/host-config

# Access the newly created VM
multipass shell $LOAD_BALANCE_HOSTNAME <<EOF

# Update the repositories
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Copy the Nginx configuration file from the mounted directory
sudo cp /mnt/host-config/nginx_lb.conf /etc/nginx/sites-available/cluster-balancer

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/cluster-balancer /etc/nginx/sites-enabled/

# Verify the correctness of the Nginx configuration
sudo nginx -t

# Reload Nginx to apply the new configuration
sudo systemctl reload nginx

sudo systemctl enable nginx

EOF

# Unmount the directory from the VM
multipass umount $LOAD_BALANCE_HOSTNAME:/mnt/host-config

# Rimuovi il file di configurazione temporaneo
rm -rf "$nginx_config"

# List the VMs
multipass list

# Get the IP address of the VM
VM_IP=$(multipass info $LOAD_BALANCE_HOSTNAME | grep IPv4 | awk '{print $2}')

echo
echo

# Print instructions to add to the host's /etc/hosts file
msg_warn "Add the following line to the /etc/hosts file of the host:"
msg_warn "$VM_IP $LOAD_BALANCE_HOSTNAME demo-go.loc demo-php.loc"
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