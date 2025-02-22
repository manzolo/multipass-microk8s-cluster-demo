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

# Trova tutte le istanze esistenti di ${VM_NODE_PREFIX}X
node_instances=$(multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}')

# Genera il file di configurazione di Nginx
nginx_config="${HOST_DIR_NAME}/config/nginx_lb.conf"

# Sostituisci le variabili d'ambiente nel template
VARIABLES_TO_REPLACE='$VM_MAIN_NAME $VM_NODE_PREFIX $DNS_SUFFIX'
envsubst "$VARIABLES_TO_REPLACE" < ${HOST_DIR_NAME}/config/nginx_lb.template > "$nginx_config"

# Aggiungi tutte le istanze di k8s-node{n} al file di configurazione
for node in $node_instances; do
  sed -i "/upstream k8s-cluster-go {/a\    server ${node}.${DNS_SUFFIX}:31001;" "$nginx_config"
  sed -i "/upstream k8s-cluster-php {/a\    server ${node}.${DNS_SUFFIX}:31002;" "$nginx_config"
done

# Mount a directory from the host into the VM
multipass mount ${HOST_DIR_NAME}/config $LOAD_BALANCE_HOSTNAME:/mnt/host-config

# Access the newly created VM
multipass shell $LOAD_BALANCE_HOSTNAME  > /dev/null 2>&1 <<EOF

# Update the repositories
sudo apt -qq update > /dev/null 2>&1

# Install Nginx
sudo apt -yq install nginx > /dev/null 2>&1

# Copy the Nginx configuration file from the mounted directory
sudo cp /mnt/host-config/nginx_lb.conf /etc/nginx/sites-available/cluster-balancer

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/cluster-balancer /etc/nginx/sites-enabled/

# Verify the correctness of the Nginx configuration
sudo nginx -t

# Reload Nginx to apply the new configuration
sudo systemctl reload nginx > /dev/null 2>&1

sudo systemctl enable nginx > /dev/null 2>&1

EOF

# Unmount the directory from the VM
multipass umount $LOAD_BALANCE_HOSTNAME:/mnt/host-config

# Rimuovi il file di configurazione temporaneo
rm -rf "$nginx_config"

# List the VMs
multipass list

VM_IP=$(multipass info $LOAD_BALANCE_HOSTNAME | grep IPv4 | awk '{print $2}')

add_machine_to_dns "demo-go" $VM_IP
add_machine_to_dns "demo-php" $VM_IP
add_machine_to_dns "static-site" $VM_IP


# MOTD generation with color codes
MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Load Balancer Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 3)$(tput bold)🖥️ Check nginx configuration:$(tput sgr0)
$(tput setaf 3)sudo nginx -t$(tput sgr0)

$(tput setaf 6)$(tput bold)👀 Check Nginx file configuration:$(tput sgr0)
$(tput setaf 6)sudo cat /etc/nginx/sites-available/cluster-balancer$(tput sgr0)

$(tput setaf 7)$(tput bold)👀 Check Nginx Service status:$(tput sgr0)
$(tput setaf 7)sudo systemctl status nginx.service$(tput sgr0)

$(tput setaf 5)$(tput bold)🔄 Restart Nginx Service:$(tput sgr0)
$(tput setaf 5)sudo systemctl restart nginx.service$(tput sgr0)

$(tput setaf 8)$(tput bold)👀 Check systemd resolved configuration:$(tput sgr0)
$(tput setaf 8)cat /etc/systemd/resolved.conf.d/dns-loc.conf$(tput sgr0)

$(tput sgr0)

http://demo-go.${DNS_SUFFIX}
http://demo-php.${DNS_SUFFIX}
http://static-site.${DNS_SUFFIX}


ping ${VM_MAIN_NAME}.${DNS_SUFFIX}
ping demo-php.${DNS_SUFFIX}
ping demo-go.${DNS_SUFFIX}
ping static-site.${DNS_SUFFIX}
ping ${VM_NODE_PREFIX}1.${DNS_SUFFIX}
ping ${DNS_VM_NAME}.${DNS_SUFFIX}

EOF
)

msg_warn "Add ${LOAD_BALANCE_HOSTNAME} MOTD"
multipass exec ${LOAD_BALANCE_HOSTNAME} -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${LOAD_BALANCE_HOSTNAME}:"
echo "$MOTD_COMMANDS"
EOF


read -n 1 -s -r -p "Press any key to continue..."
echo

# # Get the IP address of the VM
# VM_IP=$(multipass info $LOAD_BALANCE_HOSTNAME | grep IPv4 | awk '{print $2}')

# echo
# echo

# # Print instructions to add to the host's /etc/hosts file
# msg_warn "Add the following line to the /etc/hosts file of the host:"
# msg_warn "$VM_IP $LOAD_BALANCE_HOSTNAME demo-go.${DNS_SUFFIX} demo-php.${DNS_SUFFIX}"
# echo

# # Ask the user if they want to execute the command
# while true; do
#     read -r -p "Do you want to execute this command now? (y/n): " choice
#     case "$choice" in
#         y|Y)
#             break  # Exit the loop if the user says yes
#             ;;
#         n|N)
#             echo "Skipping /etc/hosts update."
#             exit 0 # Return 0 to indicate that the operation was skipped, not an error.
#             ;;
#         *)
#             echo "Invalid input. Please enter 'y' or 'n'."
#             ;;
#     esac
# done

# # Check if the line already exists and update or add it
# if grep -q "$LOAD_BALANCE_HOSTNAME demo-go.${DNS_SUFFIX} demo-php.${DNS_SUFFIX}" /etc/hosts; then
#     msg_info "Updating /etc/hosts..."
#     if sudo sed -i.bak -E "/$LOAD_BALANCE_HOSTNAME demo-go.${DNS_SUFFIX} demo-php.${DNS_SUFFIX}/ s/^[0-9.]+/$VM_IP/" /etc/hosts; then
#         msg_info "Updated /etc/hosts. Backup created as /etc/hosts.bak."
#     else
#         msg_error "Error updating /etc/hosts."
#         exit 1 # 1 to indicate an error
#     fi
# else
#     msg_info "Adding entry to /etc/hosts..."
#     if echo "$VM_IP $LOAD_BALANCE_HOSTNAME demo-go.${DNS_SUFFIX} demo-php.${DNS_SUFFIX}" | sudo tee -a /etc/hosts; then
#         msg_info "Added entry to /etc/hosts."
#     else
#         msg_error "Error adding entry to /etc/hosts."
#         exit 1 # 1 to indicate an error
#     fi
# fi