#!/bin/bash

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

NC=$'\033[0m' # No Color

function msg_info() {
  local GREEN=$'\033[0;32m'
  printf "%s\n" "${GREEN}${*}${NC}" >&2
}

function msg_warn() {
  local BROWN=$'\033[0;33m'
  printf "%s\n" "${BROWN}${*}${NC}" >&2
}

function msg_error() {
  local RED=$'\033[0;31m'
  printf "%s\n" "${RED}${*}${NC}" >&2
}

function msg_fatal() {
  msg_error "${*}"
  exit 1
}

check_command_exists() {
    if ! command -v $1 &> /dev/null
    then
        msg_error "$1 could not be found!"
        exit 1
    fi
}

run_command_on_node() {
    node_name=$1
    command=$2
    multipass exec -v ${node_name} -- ${command}
}

# Function to create a VM
create_vm() {
    local vm_name=$1
    local ram=$2
    local hdd=$3
    local cpu=$4

    msg_warn "Creating VM: $vm_name"
    if ! multipass launch $DEFAULT_UBUNTU_VERSION -m $ram -d $hdd -c $cpu -n $vm_name; then
        msg_error "Failed to create VM: $vm_name"
        exit 1
    fi
    multipass info $vm_name
}

# Function to clone a VM
clone_vm() {
    local vm_src=$VM_MAIN_NAME
    local vm_dst=$1

    msg_warn "Clone VM: $vm_src"
    if ! multipass clone $vm_src -n $vm_dst; then
        msg_error "Failed to clone VM: $vm_src"
        exit 1
    fi
}

# Function to mount host directory
mount_host_dir() {
    local vm_name=$1

    msg_warn "Mounting host directory to $vm_name"
    if ! multipass mount ${HOST_DIR_NAME} $vm_name; then
        msg_error "Failed to mount directory to $vm_name"
        exit 1
    fi
}

