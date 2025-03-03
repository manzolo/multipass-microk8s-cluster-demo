#!/bin/bash
set -e

# Include functions
source $(dirname $0)/script/functions/common.sh
source $(dirname $0)/script/functions/node.sh
source $(dirname $0)/script/functions/vm.sh
source $(dirname $0)/script/functions/dns.sh
source $(dirname $0)/script/functions/nginx.sh
source $(dirname $0)/script/functions/rancher.sh
source $(dirname $0)/script/functions/cluster.sh
source $(dirname $0)/script/functions/motd.sh

# Load default values and environment variables
source $(dirname $0)/script/functions/load_env.sh

# Validate inputs
validate_inputs

# Start Time
start_time=$(date +"%d/%m/%Y %H:%M:%S")
echo "Script started at: $start_time"

# Check prerequisites
msg_warn "Checking prerequisites..."
check_command_exists "multipass"

# Create and configure Dns Server
create_dns_server

# Create and configure VMs
main_vm_setup

# Create worker node VMs
add_node $instances

restart_microk8s_nodes

sleep 5

# Complete microk8s setup
complete_microk8s_setup

# Display cluster info and test services
cluster_setup_complete

show_cluster_info

# End Time
end_time=$(date +"%d/%m/%Y %H:%M:%S")
echo "Script finished at: $end_time"
