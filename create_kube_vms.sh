#!/bin/bash
set -e

HOST_DIR_NAME=${PWD}

# Include functions
source $(dirname $0)/script/__functions.sh

# Default values (fallback if not in .env) - These are now overridden by .env
DEFAULT_UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}" # Use .env var if set, else default
DEFAULT_INSTANCES="${INSTANCES:-2}"
DEFAULT_MAIN_CPU="${MAIN_CPU:-2}"
DEFAULT_MAIN_RAM="${MAIN_RAM:-2Gb}"
DEFAULT_MAIN_HDD_GB="${MAIN_HDD_GB:-10Gb}"
DEFAULT_NODE_CPU="${NODE_CPU:-1}"
DEFAULT_NODE_RAM="${NODE_RAM:-2Gb}"
DEFAULT_NODE_HDD_GB="${NODE_HDD_GB:-10Gb}"

#------------------- Env vars (now using defaults overridden by .env)---------------------------------------------
instances="${1:-$DEFAULT_INSTANCES}"           # Number of nodes
mainCpu="${2:-$DEFAULT_MAIN_CPU}"               # CPU for main VM
mainRam="${3:-$DEFAULT_MAIN_RAM}"             # RAM for main VM
mainHddGb="${4:-$DEFAULT_MAIN_HDD_GB}"          # HDD for main VM
nodeCpu="${5:-$DEFAULT_NODE_CPU}"               # CPU for node VM
nodeRam="${6:-$DEFAULT_NODE_RAM}"             # RAM for node VM
nodeHddGb="${7:-$DEFAULT_NODE_HDD_GB}"          # HDD for node VM
#--------------------------------------------------------------------------

# Validate inputs
if ! [[ "$instances" =~ ^[0-9]+$ ]]; then
    msg_error "Invalid number of instances: $instances"
    exit 1
fi

# Start Time
start_time=$(date +"%d/%m/%Y %H:%M:%S")
echo "Script started at: $start_time"

msg_warn "Checking prerequisites..."
check_command_exists "multipass"

# Create main VM
create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"
mount_host_dir $VM_MAIN_NAME

# Install microk8s
msg_info "=== Task 1: Installing microk8s on ${VM_MAIN_NAME} ==="
run_command_on_node $VM_MAIN_NAME "script/_install_microk8s.sh"

multipass stop $VM_MAIN_NAME

# Create node VMs
for ((counter=1; counter<=instances; counter++)); do
    clone_vm "${VM_NODE_PREFIX}$counter"
    multipass start "${VM_NODE_PREFIX}$counter"
    multipass info "${VM_NODE_PREFIX}$counter"
done

multipass start $VM_MAIN_NAME

# Create hosts file
msg_warn "Generating /etc/hosts entries..."
multipass list | grep "k8s-" | grep -E -v "Name|\-\-" | awk '{var=sprintf("%s\t%s",$3,$1); print var".loc"}' > config/hosts

# Join nodes to cluster
msg_info "=== Task 2: Configuring worker nodes ==="
for ((counter=1; counter<=instances; counter++)); do
    rm -rf script/_join_node.sh
    msg_warn "Generating join cluster command for ${VM_MAIN_NAME}"
    run_command_on_node $VM_MAIN_NAME "script/_join_cluster_helper.sh"

    msg_warn "Installing microk8s on ${VM_NODE_PREFIX}$counter"
    run_command_on_node "${VM_NODE_PREFIX}$counter" "script/_install_microk8s.sh"
done

# Wait for cluster to be ready
msg_warn "Waiting for microk8s to be ready..."
while ! multipass exec ${VM_MAIN_NAME} -- microk8s status --wait-ready; do
    sleep 10
done

# Complete microk8s setup
msg_info "=== Task 3: Completing microk8s setup ==="
run_command_on_node $VM_MAIN_NAME "script/_rollout_pods.sh"

# Unmount directories
msg_warn "Unmounting directories..."
multipass umount ${VM_MAIN_NAME}:$(multipass info ${VM_MAIN_NAME} | grep Mounts | awk '{print $4}')
for ((counter=1; counter<=instances; counter++)); do
    multipass umount "${VM_NODE_PREFIX}$counter:$(multipass info "${VM_NODE_PREFIX}$counter" | grep Mounts | awk '{print $4}')"
done

# Display cluster info
multipass list | grep -i "k8s-"

# Test services
IP=$(multipass info ${VM_MAIN_NAME} | grep IPv4 | awk '{print $2}')
NODEPORT_GO=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
NODEPORT_PHP=$(multipass exec ${VM_MAIN_NAME} -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)

# MOTD generation with color codes
MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Kubernetes Cluster Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 2)$(tput bold)🚀 Apply new configuration:$(tput sgr0)
$(tput setaf 2)kubectl apply -f config/demo-go.yaml$(tput sgr0)

$(tput setaf 3)$(tput bold)📈 Scale up to 20 demo-go pods:$(tput sgr0)
$(tput setaf 3)kubectl scale deployment demo-go --replicas=20 -n demo-go$(tput sgr0)

$(tput setaf 4)$(tput bold)📈 Scale up to 5 demo-php pods:$(tput sgr0)
$(tput setaf 4)kubectl scale deployment demo-php --replicas=5 -n demo-php$(tput sgr0)

$(tput setaf 5)$(tput bold)🔄 Show demo-go pods rollout status:$(tput sgr0)
$(tput setaf 5)kubectl rollout status deployment/demo-go -n demo-go$(tput sgr0)

$(tput setaf 6)$(tput bold)🔄 Show demo-php pods rollout status:$(tput sgr0)
$(tput setaf 6)kubectl rollout status deployment/demo-php -n demo-php$(tput sgr0)

$(tput setaf 7)$(tput bold)👀 Show demo-php pods:$(tput sgr0)
$(tput setaf 7)kubectl get all -o wide -n demo-php$(tput sgr0)

$(tput setaf 8)$(tput bold)👀 Show demo-go pods:$(tput sgr0)
$(tput setaf 8)kubectl get all -o wide -n demo-go$(tput sgr0)

$(tput setaf 9)$(tput bold)🖥️ Show node details:$(tput sgr0)
$(tput setaf 9)kubectl get node$(tput sgr0)

$(tput sgr0)
EOF
)

msg_warn "Add ${VM_MAIN_NAME} MOTD"
multipass exec ${VM_MAIN_NAME} -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${VM_MAIN_NAME}:"
echo "$MOTD_COMMANDS"
EOF

msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-go --replicas=10 -n demo-go"
multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-go --replicas=10 -n demo-go

msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-php --replicas=10 -n demo-php"
multipass exec ${VM_MAIN_NAME} -- kubectl scale deployment demo-php --replicas=10 -n demo-php

msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-go"
multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-go
msg_warn "multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-php"
multipass exec ${VM_MAIN_NAME} -- kubectl get all -o wide -n demo-php

msg_warn "Enter on ${VM_MAIN_NAME}:"
msg_info "multipass shell ${VM_MAIN_NAME}"

msg_warn "Testing Golang service:"
msg_info "curl -s http://$IP:$NODEPORT_GO"

# Clean temp files
temp_file="${HOST_DIR_NAME}/script/_test.sh"
trap "rm -f $temp_file" EXIT
echo "curl -s http://$IP:$NODEPORT_GO" > "$temp_file"
chmod +x "$temp_file"
"$temp_file"

echo

msg_warn "Testing PHP service:"
msg_info "http://$IP:$NODEPORT_PHP"

# End Time
end_time=$(date +"%d/%m/%Y %H:%M:%S")
echo "Script finished at: $end_time"
