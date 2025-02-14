#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

#------------------- Env vars ---------------------------------------------
instances="${1:-2}"           # Number of nodes
mainCpu=${2:-2}               # CPU for main VM
mainRam=${3:-2Gb}             # RAM for main VM
mainHddGb=${4:-10Gb}          # HDD for main VM
nodeCpu=${5:-1}               # CPU for node VM
nodeRam=${6:-2Gb}             # RAM for node VM
nodeHddGb=${7:-10Gb}          # HDD for node VM
#--------------------------------------------------------------------------

# Include functions
source $(dirname $0)/script/__functions.sh

# Validate inputs
if ! [[ "$instances" =~ ^[0-9]+$ ]]; then
    msg_error "Invalid number of instances: $instances"
    exit 1
fi

# Clean temp files
temp_file="${HOST_DIR_NAME}/script/_test.sh"
trap "rm -f $temp_file" EXIT

msg_warn "Checking prerequisites..."
check_command_exists "multipass"

# Function to create a VM
create_vm() {
    local vm_name=$1
    local ram=$2
    local hdd=$3
    local cpu=$4

    msg_warn "Creating VM: $vm_name"
    if ! multipass launch -m $ram -d $hdd -c $cpu -n $vm_name; then
        msg_error "Failed to create VM: $vm_name"
        exit 1
    fi
    multipass info $vm_name
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

# Create main VM
create_vm "k8s-main" "$mainRam" "$mainHddGb" "$mainCpu"

# Create node VMs
for ((counter=1; counter<=instances; counter++)); do
    create_vm "k8s-node$counter" "$nodeRam" "$nodeHddGb" "$nodeCpu"
done

# Create hosts file
msg_warn "Generating /etc/hosts entries..."
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var".loc"}' > config/hosts

# Mount host directory
msg_info "=== Task 1: Mount host drive with installation scripts ==="
mount_host_dir "k8s-main"
for ((counter=1; counter<=instances; counter++)); do
    mount_host_dir "k8s-node$counter"
done

# Install microk8s
msg_info "=== Task 2: Installing microk8s on k8s-main ==="
run_command_on_node "k8s-main" "script/_install_microk8s.sh"

# Join nodes to cluster
msg_info "=== Task 3: Installing Kubernetes on worker nodes ==="
for ((counter=1; counter<=instances; counter++)); do
    rm -rf script/_join_node.sh
    msg_warn "Generating join cluster command for k8s-main"
    run_command_on_node "k8s-main" "script/_join_cluster_helper.sh"

    msg_warn "Installing microk8s on k8s-node$counter"
    run_command_on_node "k8s-node$counter" "script/_install_microk8s.sh"
done

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec k8s-main -- microk8s status --wait-ready; do
    sleep 10
done

# Complete microk8s setup
msg_info "=== Task 4: Completing microk8s setup ==="
run_command_on_node "k8s-main" "script/_complete_microk8s.sh"

# Unmount directories
msg_warn "Unmounting directories..."
multipass umount k8s-main:$(multipass info k8s-main | grep Mounts | awk '{print $4}')
for ((counter=1; counter<=instances; counter++)); do
    multipass umount "k8s-node$counter:$(multipass info "k8s-node$counter" | grep Mounts | awk '{print $4}')"
done

# Display cluster info
multipass list

# Test services
IP=$(multipass info k8s-main | grep IPv4 | awk '{print $2}')
NODEPORT_GO=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
NODEPORT_PHP=$(multipass exec k8s-main -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)

msg_warn "Testing Golang service:"
msg_info "curl -s http://$IP:$NODEPORT_GO"
echo "curl -s http://$IP:$NODEPORT_GO" > "$temp_file"
chmod +x "$temp_file"
"$temp_file"

echo

msg_warn "Testing PHP service:"
msg_info "http://$IP:$NODEPORT_PHP"