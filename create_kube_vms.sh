#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

# Include functions
# shellcheck source=script/functions/common.sh
source "${SCRIPT_DIR}/script/functions/common.sh"
# shellcheck source=script/functions/node.sh
source "${SCRIPT_DIR}/script/functions/node.sh"
# shellcheck source=script/functions/vm.sh
source "${SCRIPT_DIR}/script/functions/vm.sh"
# shellcheck source=script/functions/dns.sh
source "${SCRIPT_DIR}/script/functions/dns.sh"
# shellcheck source=script/functions/nginx.sh
source "${SCRIPT_DIR}/script/functions/nginx.sh"
# shellcheck source=script/functions/rancher.sh
source "${SCRIPT_DIR}/script/functions/rancher.sh"
# shellcheck source=script/functions/cluster.sh
source "${SCRIPT_DIR}/script/functions/cluster.sh"
# shellcheck source=script/functions/motd.sh
source "${SCRIPT_DIR}/script/functions/motd.sh"

create_env_local

# Load default values and environment variables
# shellcheck source=script/functions/load_env.sh
source "${SCRIPT_DIR}/script/functions/load_env.sh"

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

# Save VM for cloning
k8s_vm_save_template

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
