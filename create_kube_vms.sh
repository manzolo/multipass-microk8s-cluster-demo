#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Include functions
source $(dirname $0)/script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/script/__load_env.sh

# Validate inputs
source $(dirname $0)/script/__validate_inputs.sh

# Start Time
start_time=$(date +"%d/%m/%Y %H:%M:%S")
echo "Script started at: $start_time"

# Check prerequisites
msg_warn "Checking prerequisites..."
check_command_exists "multipass"

# Create and configure Dns Server
source $(dirname $0)/script/__create_dns_server.sh

# Create and configure VMs
source $(dirname $0)/script/__create_main_vm.sh

# Configure main VM
source $(dirname $0)/script/__setup_main_vm.sh

# Create worker node VMs
for ((counter=1; counter<=instances; counter++)); do
    # Install and configure microk8s
    $(dirname $0)/cmd/add_node.sh
    #store_install_dir ${VM_NODE_PREFIX}${counter}
done

restart_microk8s_nodes

sleep 5

# Complete microk8s setup
source $(dirname $0)/script/__complete_microk8s_setup.sh

#store_install_dir $VM_MAIN_NAME

## Unmount directories
#source $(dirname $0)/script/__unmount_directories.sh

# Display cluster info and test services
source $(dirname $0)/script/__display_cluster_info.sh

show_cluster_info

# End Time
end_time=$(date +"%d/%m/%Y %H:%M:%S")
echo "Script finished at: $end_time"
