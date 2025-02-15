#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

# Default values (fallback if not in .env) - These are now overridden by .env
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}" # Use .env var if set, else default
DEFAULT_INSTANCES="${INSTANCES:-2}"
DEFAULT_MAIN_CPU="${MAIN_CPU:-2}"
DEFAULT_MAIN_RAM="${MAIN_RAM:-2Gb}"
DEFAULT_MAIN_HDD_GB="${MAIN_HDD_GB:-10Gb}"
DEFAULT_NODE_CPU="${NODE_CPU:-1}"
DEFAULT_NODE_RAM="${NODE_RAM:-2Gb}"
DEFAULT_NODE_HDD_GB="${NODE_HDD_GB:-10Gb}"

# ... (rest of your script)

#------------------- Env vars (now using defaults overridden by .env)---------------------------------------------
instances="${1:-$DEFAULT_INSTANCES}"           # Number of nodes
mainCpu="${2:-$DEFAULT_MAIN_CPU}"               # CPU for main VM
mainRam="${3:-$DEFAULT_MAIN_RAM}"             # RAM for main VM
mainHddGb="${4:-$DEFAULT_MAIN_HDD_GB}"          # HDD for main VM
nodeCpu="${5:-$DEFAULT_NODE_CPU}"               # CPU for node VM
nodeRam="${6:-$DEFAULT_NODE_RAM}"             # RAM for node VM
nodeHddGb="${7:-$DEFAULT_NODE_HDD_GB}"          # HDD for node VM
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
    multipass info $vm_dst
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
create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"
multipass stop $VM_MAIN_NAME

# Create node VMs
for ((counter=1; counter<=instances; counter++)); do
    clone_vm "k8s-node$counter"
    multipass start "k8s-node$counter"
done

multipass start $VM_MAIN_NAME

# Create hosts file
msg_warn "Generating /etc/hosts entries..."
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var".loc"}' > config/hosts

# Mount host directory
msg_info "=== Task 1: Mount host drive with installation scripts ==="
mount_host_dir $VM_MAIN_NAME
for ((counter=1; counter<=instances; counter++)); do
    mount_host_dir "k8s-node$counter"
done

# Install microk8s
msg_info "=== Task 2: Installing microk8s on ${VM_MAIN_NAME} ==="
run_command_on_node $VM_MAIN_NAME "script/_install_microk8s.sh"

# Join nodes to cluster
msg_info "=== Task 3: Installing Kubernetes on worker nodes ==="
for ((counter=1; counter<=instances; counter++)); do
    rm -rf script/_join_node.sh
    msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
    run_command_on_node $VM_MAIN_NAME "script/_join_cluster_helper.sh"

    msg_warn "Installing microk8s on k8s-node$counter"
    run_command_on_node "k8s-node$counter" "script/_install_microk8s.sh"
done

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready; do
    sleep 10
done

# Complete microk8s setup
msg_info "=== Task 4: Completing microk8s setup ==="
run_command_on_node $VM_MAIN_NAME "script/_complete_microk8s.sh"

# Unmount directories
msg_warn "Unmounting directories..."
multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
for ((counter=1; counter<=instances; counter++)); do
    multipass umount "k8s-node$counter:$(multipass info "k8s-node$counter" | grep Mounts | awk '{print $4}')"
done

# Display cluster info
multipass list | grep -i "k8s-"

# Test services
IP=$(multipass info ${VM_MAIN_NAME} | grep IPv4 | awk '{print $2}')
NODEPORT_GO=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
NODEPORT_PHP=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)

# MOTD generation with color codes
MOTD_COMMANDS=$(cat <<EOF
# Apply new configuration
$(tput setaf 2)kubectl apply -f config/demo-go.yaml$(tput sgr0)
# Scale up to 20 demo-go pods
$(tput setaf 3)kubectl scale deployment demo-go --replicas=20 -n demo-go$(tput sgr0)
# Scale up to 5 demo-php pods
$(tput setaf 4)kubectl scale deployment demo-php --replicas=5 -n demo-php$(tput sgr0)
# Show demo-go pods rollout status
$(tput setaf 5)kubectl rollout status deployment/demo-go -n demo-go$(tput sgr0)
# Show demo-php pods rollout status
$(tput setaf 6)kubectl rollout status deployment/demo-php -n demo-php$(tput sgr0)
# Show demo-go pods
$(tput setaf 1)kubectl get all -o wide -n demo-go$(tput sgr0)
EOF
)

msg_warn "Add ${VM_MAIN_NAME} MOTD:"
multipass exec ${VM_MAIN_NAME} -- sudo tee -a /home/ubuntu/.bashrc <<EOF
echo ""
echo "Commands to run on ${VM_MAIN_NAME}:"
echo "$MOTD_COMMANDS"
EOF

msg_warn "Enter on ${VM_MAIN_NAME}:"
msg_info "multipass shell ${VM_MAIN_NAME}"

msg_warn "Testing Golang service:"
msg_info "curl -s http://$IP:$NODEPORT_GO"
echo "curl -s http://$IP:$NODEPORT_GO" > "$temp_file"
chmod +x "$temp_file"
"$temp_file"

echo

msg_warn "Testing PHP service:"
msg_info "http://$IP:$NODEPORT_PHP"
