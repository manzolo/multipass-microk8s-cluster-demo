#!/bin/bash
set -e

# Function to launch the VM
launch_nginx_vm() {
  multipass launch "$DEFAULT_UBUNTU_VERSION" -m 2Gb -d 5Gb -c 1 -n "$LOAD_BALANCE_HOSTNAME"
  add_machine_to_dns "$LOAD_BALANCE_HOSTNAME"
  restart_dns_service
}

# Function to generate Nginx config
generate_nginx_config() {
  local nginx_config="${CONFIG_DIR}/nginx_lb.conf"
  local VARIABLES_TO_REPLACE='$VM_MAIN_NAME $VM_NODE_PREFIX $DNS_SUFFIX'

  envsubst "$VARIABLES_TO_REPLACE" < "${CONFIG_DIR}/nginx_lb.template" > "$nginx_config"

  local node_instances=$(multipass list | grep "$VM_NODE_PREFIX" | awk '{print $1}')
  for node in $node_instances; do
    sed -i "/upstream k8s-cluster-go {/a\    server ${node}.${DNS_SUFFIX}:31001;" "$nginx_config"
    sed -i "/upstream k8s-cluster-php {/a\    server ${node}.${DNS_SUFFIX}:31002;" "$nginx_config"
    sed -i "/upstream k8s-cluster-static-site {/a\    server ${node}.${DNS_SUFFIX}:31003;" "$nginx_config"
    sed -i "/upstream k8s-cluster-phpmyadmin {/a\    server ${node}.${DNS_SUFFIX}:31011;" "$nginx_config"
    sed -i "/upstream k8s-cluster-mongodb {/a\    server ${node}.${DNS_SUFFIX}:31012;" "$nginx_config"
    sed -i "/upstream k8s-cluster-pgadmin {/a\    server ${node}.${DNS_SUFFIX}:31013;" "$nginx_config"
    sed -i "/upstream k8s-cluster-kibana {/a\    server ${node}.${DNS_SUFFIX}:31014;" "$nginx_config"
  done
  multipass transfer "$nginx_config" "$LOAD_BALANCE_HOSTNAME:/tmp/nginx_lb.conf"
  rm -rf "$nginx_config"
}

# Function to configure Nginx inside the VM
configure_nginx_in_vm() {
  multipass shell "$LOAD_BALANCE_HOSTNAME" > /dev/null 2>&1 <<EOF
    sudo apt -qq update > /dev/null 2>&1
    sudo apt -yq install nginx > /dev/null 2>&1
    sudo cp /tmp/nginx_lb.conf /etc/nginx/sites-available/cluster-balancer
    sudo ln -s /etc/nginx/sites-available/cluster-balancer /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo systemctl reload nginx > /dev/null 2>&1
    sudo systemctl enable nginx > /dev/null 2>&1
    rm /tmp/nginx_lb.conf
EOF
}

# Function to add DNS entries
add_nginx_dns_entries() {
  local VM_IP=$(multipass info "$LOAD_BALANCE_HOSTNAME" | grep IPv4 | awk '{print $2}')
  add_machine_to_dns "demo-go" "$VM_IP"
  add_machine_to_dns "demo-php" "$VM_IP"
  add_machine_to_dns "static-site" "$VM_IP"
  add_machine_to_dns "phpmyadmin" "$VM_IP"
  add_machine_to_dns "mongodb" "$VM_IP"
  add_machine_to_dns "pgadmin" "$VM_IP"
  add_machine_to_dns "kibana" "$VM_IP"
  restart_dns_service
}

# Function to generate MOTD
generate_nginx_motd() {
  local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Load Balancer Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 3)$(tput bold)️👀 Check nginx configuration:$(tput sgr0)
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
http://phpmyadmin.${DNS_SUFFIX}

ping ${DNS_VM_NAME}.${DNS_SUFFIX}
ping ${VM_MAIN_NAME}.${DNS_SUFFIX}
ping ${VM_NODE_PREFIX}1.${DNS_SUFFIX}

ping demo-php.${DNS_SUFFIX}
ping demo-go.${DNS_SUFFIX}
ping static-site.${DNS_SUFFIX}
ping phpmyadmin.${DNS_SUFFIX}

EOF
)
  msg_warn "Add ${LOAD_BALANCE_HOSTNAME} MOTD"
  multipass exec "$LOAD_BALANCE_HOSTNAME" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
    echo ""
    echo "Commands to run on ${LOAD_BALANCE_HOSTNAME}:"
    echo "$MOTD_COMMANDS"
EOF
}

function create_nginx_lb() {
  # Main script execution
  launch_nginx_vm
  generate_nginx_config
  configure_nginx_in_vm
  add_nginx_dns_entries
  generate_nginx_motd
}

function destroy_nginx_lb() {
    remove_machine_from_dns $LOAD_BALANCE_HOSTNAME
    remove_machine_from_dns demo-go
    remove_machine_from_dns demo-php
    remove_machine_from_dns static-site

    restart_dns_service    
    multipass stop --force $LOAD_BALANCE_HOSTNAME > /dev/null 2>&1
    multipass delete --purge $LOAD_BALANCE_HOSTNAME > /dev/null 2>&1
    multipass purge > /dev/null 2>&1
}