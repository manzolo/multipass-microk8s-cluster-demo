#!/bin/bash

HOST_DIR_NAME=${PWD}

#Include functions
source $(dirname $0)/../script/__functions.sh

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

# Reload Nginx to apply the new configuration
sudo systemctl reload nginx

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
msg_info "$VM_IP nginx-cluster-balancer demo-go.loc demo-php.loc"
