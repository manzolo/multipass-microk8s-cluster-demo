#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Include functions
source $(dirname $0)/../script/__functions.sh

# Default values (fallback if not in .env) - These are now overridden by .env
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}" # Use .env var if set, else default
# Launch a new VM with the specified requirements
multipass launch $DEFAULT_UBUNTU_VERSION -m 2Gb -d 5Gb -c 1 -n nginx-cluster-balancer

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
  echo "Errore: almeno una VM non ha un IP:" >&2
  echo "$missing_ips" >&2
  exit 1
fi

# Trova tutte le istanze esistenti di ${VM_NODE_PREFIX}X
node_instances=$(multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}')

# Genera il file di configurazione di Nginx
nginx_config="${HOST_DIR_NAME}/config/nginx_lb.conf"

# Sostituisci le variabili d'ambiente nel template
VARIABLES_TO_REPLACE='$VM_MAIN_NAME $VM_NODE_PREFIX'
envsubst "$VARIABLES_TO_REPLACE" < ${HOST_DIR_NAME}/config/nginx_lb.template > "$nginx_config"

# Aggiungi tutte le istanze di k8s-node{n} al file di configurazione
for node in $node_instances; do
  sed -i "/upstream k8s-cluster-go {/a\    server ${node}.loc:31001;" "$nginx_config"
  sed -i "/upstream k8s-cluster-php {/a\    server ${node}.loc:31002;" "$nginx_config"
done

# Mount a directory from the host into the VM
multipass mount ${HOST_DIR_NAME}/config nginx-cluster-balancer:/mnt/host-config

# Access the newly created VM
multipass shell nginx-cluster-balancer <<EOF

sudo tee -a /etc/hosts <<<"$K8S_HOSTS"
sudo tee -a /etc/cloud/templates/hosts.debian.tmpl <<<"$K8S_HOSTS"

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
multipass umount nginx-cluster-balancer:/mnt/host-config

# Rimuovi il file di configurazione temporaneo
rm -rf "$nginx_config"

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