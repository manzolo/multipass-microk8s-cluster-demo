#!/bin/bash

HOST_DIR_NAME=${PWD}

#Include functions
source $(dirname $0)/../script/__functions.sh

# Launch a new VM with the specified requirements
multipass launch -m 4Gb -d 20Gb -c 1 -n rancher

multipass start rancher

# Access the newly created VM
multipass shell rancher <<EOF

# Update the repositories
sudo apt update

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
EOF

# Enable docker
multipass shell rancher <<EOF
sudo usermod -aG docker ubuntu
sudo systemctl unmask docker
sudo systemctl enable docker
sudo systemctl start docker
group=docker
EOF

# Start rancher
multipass shell rancher <<EOF
docker run -d \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  --privileged \
  --name rancher \
  rancher/rancher:v2.9.2
EOF

echo
echo

# Get the IP address of the VM
VM_IP=$(multipass info rancher | grep IPv4 | awk '{print $2}')

# Print instructions to add to the host's /etc/hosts file
msg_warn "Add the following line to the /etc/hosts file of the host:"
msg_info "$VM_IP rancher.loc"

msg_warn "Please wait while Rancher starts up, then navigate to https://rancher.loc"
msg_warn "multipass shell rancher"
msg_warn 'docker logs rancher 2>&1 | grep "Bootstrap Password:"'


