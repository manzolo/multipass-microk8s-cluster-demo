#!/bin/bash

set -e

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

function remove_vm() {
    local vm_name=$1

    # Verifica se la VM esiste
    if multipass list | grep -q "$vm_name"; then
        msg_warn "Removing VM: $vm_name..."
        multipass delete --purge "$vm_name" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            msg_warn "VM $vm_name removed successfully."
        else
            msg_error "Failed to remove VM: $vm_name"
        fi
    else
        msg_warn "VM $vm_name does not exist. Skipping removal."
    fi
}

# Function to clone a VM
function clone_vm() {
    local vm_dst=$1
    local vm_src=$VM_MAIN_NAME

    if [[ $vm_dst =~ ([0-9]+)$ ]]; then
        local num=${BASH_REMATCH[1]}
        local last_existing_vm=$(multipass list | grep "$VM_NODE_PREFIX" | awk '{print $1}' | sed "s/${VM_NODE_PREFIX}//" | sort -n | tail -1)
        if [[ -n "$last_existing_vm" ]]; then
            vm_src="${VM_NODE_PREFIX}${last_existing_vm}"
        fi
    fi

    if ! multipass list | grep -q "$vm_src"; then
        msg_warn "Source VM $vm_src does not exist. Skipping clone."
        return 1
    fi

    msg_warn "Clone VM: $vm_src -> $vm_dst"

    if ! multipass clone "$vm_src" -n "$vm_dst"; then
        msg_error "Failed to clone VM: $vm_src"
        return 1
    fi
}

function install_docker() {
    local vm_name=$1
    msg_info "Installing Docker on $vm_name..."
    if ! multipass shell "$vm_name" <<EOF
#!/bin/bash
set -e
# Remove old Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y \$pkg
done

# Add Docker's official GPG key
sudo apt update -qq
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
echo \
  "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu || true # Ignore if group doesn't exist yet
sudo systemctl unmask docker
sudo systemctl enable docker
sudo systemctl start docker
EOF
    then
        msg_error "Failed to enable Docker on $vm_name."
        return 1
    fi
}

function complete_microk8s_setup() {
    wait_for_microk8s_ready "$VM_MAIN_NAME"
    msg_info "=== Task 3: Completing microk8s setup ==="

    multipass transfer -r config $VM_MAIN_NAME:/home/ubuntu/microk8s_demo_config

    declare -A deployments # Dichiarazione dell'array associativo

    deployments["demo-go"]=""
    deployments["demo-php"]=""
    deployments["static-site"]=""
    deployments["mariadb"]="deployment=phpmyadmin"
    deployments["mongodb"]="deployment=mongodb-express"
    deployments["postgres"]="deployment=pgadmin"
    deployments["elk"]="deployment=kibana"
    deployments["redis"]="deployment=redis-commander"
    deployments["rabbitmq"]=""
    deployments["jenkins"]=""

    function deploy_app() {
        local app_name="$1"
        local deploy_info="${deployments[$app_name]}"

        local deployment="$app_name" # Default deployment name
        if [ -n "$deploy_info" ]; then
            deployment=$(echo "$deploy_info" | awk -F'deployment=' '{print $2}')
        fi

        local deploy_var="DEPLOY_$(echo "$app_name" | tr '[:lower:]-' '[:upper:]_')"

        if [ -z "${!deploy_var}" ]; then
            msg_warn "Variable $deploy_var is not defined. Skipping $app_name deployment."
            return 0
        fi

        if eval "[ \${$deploy_var} = 'true' ]"; then
            if ! multipass exec $VM_MAIN_NAME -- bash -c "cat /home/ubuntu/microk8s_demo_config/$app_name.yaml | envsubst | kubectl apply -f -"; then
                msg_error "Failed to apply $app_name"
                return 1
            fi

            # Verifica lo stato del deployment
            if ! multipass exec $VM_MAIN_NAME -- bash -c "kubectl rollout status deployment/$deployment -n $app_name --timeout=60s"; then
                msg_error "Failed to rollout deployment $deployment"
                return 1
            fi
        else
            msg_warn "Skipping $app_name deployment."
        fi
    }

    for app_name in "${!deployments[@]}"; do
        deploy_app "$app_name"
    done
}

function main_vm_setup(){
    create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"
    add_machine_to_dns $VM_MAIN_NAME
    restart_dns_service
    msg_info "=== Task 1: ${VM_MAIN_NAME} Setup ==="
    multipass transfer script/remote/__install_microk8s.sh $VM_MAIN_NAME:/home/ubuntu/install_microk8s.sh
    multipass exec $VM_MAIN_NAME -- /home/ubuntu/install_microk8s.sh
    multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/install_microk8s.sh
    multipass stop $VM_MAIN_NAME
}