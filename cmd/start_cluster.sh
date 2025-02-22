#!/bin/bash

set -e

HOST_DIR_NAME=${PWD}

#Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

msg_warn "Check prerequisites..."
#Check prerequisites
check_command_exists "multipass"

# Stop main VM
multipass start ${VM_MAIN_NAME}

# Stop all node VMs
for ((counter=1; counter<=instances; counter++)); do
    vm_name="${VM_NODE_PREFIX}${counter}"
    multipass start $vm_name
done

msg_info "All VMs started."
multipass list