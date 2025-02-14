#!/bin/bash

HOST_DIR_NAME=${PWD}

#Include functions
source $(dirname $0)/../script/__functions.sh

#K8S_HOSTS=$(multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var".loc"}')

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

# Se tutte le macchine hanno un IP, costruisce la lista con il formato desiderato
#K8S_HOSTS=$(multipass list \
#  | grep "k8s-" \
#  | grep -E -v "Name|\-\-" \
#  | awk '{printf "%s\t%s.loc\n", $3, $1}')

# Stampa il contenuto di K8S_HOSTS
#msg_info "Generated /etc/hosts entries:"
#echo "$K8S_HOSTS"

# Launch a new VM with the specified requirements
multipass launch -m 2Gb -d 5Gb -c 1 -n nginx-cluster-balancer

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

# Verify the correctness of the Nginx configuration
sudo nginx -t

echo "$K8S_HOSTS" | sudo tee -a /etc/hosts

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
# Verifica se la riga esiste già e sostituisci l'IP
if grep -q "nginx-cluster-balancer demo-go.loc demo-php.loc" /etc/hosts; then
    #msg_warn "La riga esiste già in /etc/hosts. Sostituisco l'IP esistente con $VM_IP..."
    msg_info 'sudo sed -i.bak -E "/nginx-cluster-balancer demo-go.loc demo-php.loc/ s/^[0-9.]+/'$VM_IP'/" /etc/hosts'
    #msg_info "Operazione completata. Backup del file originale creato come /etc/hosts.bak."
else
    #msg_info "La riga non esiste in /etc/hosts. Aggiungo una nuova riga..."
    msg_info 'echo "'$VM_IP' nginx-cluster-balancer demo-go.loc demo-php.loc" | sudo tee -a /etc/hosts'
fi
