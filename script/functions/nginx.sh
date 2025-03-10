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
  local VM_IP=$(get_vm_ip "$LOAD_BALANCE_HOSTNAME")
  add_machine_to_dns "demo-go" "$VM_IP"
  add_machine_to_dns "demo-php" "$VM_IP"
  add_machine_to_dns "static-site" "$VM_IP"
  add_machine_to_dns "phpmyadmin" "$VM_IP"
  add_machine_to_dns "mongodb" "$VM_IP"
  add_machine_to_dns "pgadmin" "$VM_IP"
  add_machine_to_dns "kibana" "$VM_IP"
  add_machine_to_dns "redis" "$VM_IP"
  add_machine_to_dns "rabbitmq" "$VM_IP"
  add_machine_to_dns "jenkins" "$VM_IP"
  restart_dns_service
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
    remove_machine_from_dns "phpmyadmin"
    remove_machine_from_dns "mongodb"
    remove_machine_from_dns "pgadmin"
    remove_machine_from_dns "kibana"
    remove_machine_from_dns "redis"
    remove_machine_from_dns "rabbitmq"
    remove_machine_from_dns "jenkins"
    restart_dns_service    
    multipass stop --force $LOAD_BALANCE_HOSTNAME > /dev/null 2>&1
    multipass delete --purge $LOAD_BALANCE_HOSTNAME > /dev/null 2>&1
    multipass purge > /dev/null 2>&1
}