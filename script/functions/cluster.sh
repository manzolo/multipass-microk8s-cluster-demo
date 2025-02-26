#!/bin/bash

set -e

function start_cluster(){
    msg_warn "Check prerequisites..."
    #Check prerequisites
    check_command_exists "multipass"

    # Start dns server VM
    multipass start ${DNS_VM_NAME}

    # Start main VM
    multipass start ${VM_MAIN_NAME}

    # Start all node VMs
    for ((counter=1; counter<=instances; counter++)); do
        vm_name="${VM_NODE_PREFIX}${counter}"
        multipass start $vm_name
    done

    msg_info "All VMs started."
    show_cluster_info

}

function stop_cluster(){
    msg_warn "Check prerequisites..."
    #Check prerequisites
    check_command_exists "multipass"

    # Stop all node VMs
    for ((counter=1; counter<=instances; counter++)); do
        vm_name="${VM_NODE_PREFIX}${counter}"
        # Check if VM is running
        if [[ $(multipass info "$vm_name" | grep "State:" | awk '{print $2}') == "Running" ]]; then
            run_command_on_node $vm_name "sudo snap stop microk8s"
        fi
        multipass stop $vm_name
    done

    # Stop main VM
    # Check if VM is running
    if [[ $(multipass info "${VM_MAIN_NAME}" | grep "State:" | awk '{print $2}') == "Running" ]]; then
        run_command_on_node ${VM_MAIN_NAME} "sudo snap stop microk8s"
    fi
    multipass stop ${VM_MAIN_NAME}
    
    # Stop dns server VM
    multipass stop ${DNS_VM_NAME}

    msg_info "All VMs stopped."

    show_cluster_info
}

# Function to test services
test_services() {
    local IP=$(multipass info "${VM_MAIN_NAME}" | grep IPv4 | awk '{print $2}')
    local NODEPORT_GO=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
    local NODEPORT_PHP=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)

    msg_warn "Testing Golang service:"
    msg_info "curl -s http://$IP:$NODEPORT_GO"

    msg_warn "Testing PHP service:"
    msg_info "http://$IP:$NODEPORT_PHP"

    # Clean temp files
    local temp_file="${INSTALL_DIR}/script/_test.sh"
    trap "rm -f $temp_file" EXIT
    echo "curl -s http://$IP:$NODEPORT_GO" > "$temp_file"
    chmod +x "$temp_file"
    "$temp_file"
}

# Function to generate MOTD
generate_main_vm_motd() {
    local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Kubernetes Cluster Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 2)$(tput bold)🚀 Apply new configuration:$(tput sgr0)
$(tput setaf 2)kubectl apply -f microk8s_demo_config/demo-go.yaml$(tput sgr0)

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

$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  Microk8s Dashboard
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)
$(tput setaf 9)$(tput bold)🖥️ Enable dashboard:$(tput sgr0)
$(tput setaf 8)microk8s enable community$(tput sgr0)
$(tput setaf 8)microk8s enable dashboard-ingress --hostname ${VM_MAIN_NAME}.${DNS_SUFFIX} --allow 0.0.0.0/0$(tput sgr0)

$(tput setaf 1)$(tput bold)🔑 Show MicroK8s Dashboard Token:$(tput sgr0)
$(tput setaf 1)kubectl describe secret -n kube-system microk8s-dashboard-token | grep "token:" | awk '{print \$'2'}'$(tput sgr0)

$(tput setaf 2)$(tput bold)🚀 Start dashboard:$(tput sgr0)
$(tput setaf 8)microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0$(tput sgr0)

$(tput setaf 5)https://${VM_MAIN_NAME}.${DNS_SUFFIX}:10443/#/login$(tput sgr0)

$(tput sgr0)
EOF
    )

    msg_warn "Add ${VM_MAIN_NAME} MOTD"
    multipass exec "${VM_MAIN_NAME}" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${VM_MAIN_NAME}:"
echo "$MOTD_COMMANDS"
EOF
}

# Function to scale and rollout deployments
scale_and_rollout_deployments() {
    msg_warn "Scaling and rolling out deployments..."

    multipass exec "${VM_MAIN_NAME}" -- kubectl scale deployment demo-go --replicas=6 -n demo-go
    multipass exec "${VM_MAIN_NAME}" -- kubectl rollout status deployment/demo-go -n demo-go

    multipass exec "${VM_MAIN_NAME}" -- kubectl scale deployment demo-php --replicas=6 -n demo-php
    multipass exec "${VM_MAIN_NAME}" -- kubectl rollout status deployment/demo-php -n demo-php
}

# Function to get all resources
get_all_resources() {
    msg_warn "Getting all resources..."

    multipass exec "${VM_MAIN_NAME}" -- kubectl get all -o wide -n demo-go
    multipass exec "${VM_MAIN_NAME}" -- kubectl get all -o wide -n demo-php
}

# Function to enter VM
enter_main_vm() {
    msg_warn "Enter on ${VM_MAIN_NAME}:"
    msg_info "multipass shell ${VM_MAIN_NAME}"
}

# Function to clean temp files
clean_temp_files() {
    msg_warn "Cleaning temporary files..."
    multipass exec "${VM_MAIN_NAME}" -- rm -rf microk8s_demo_config/*.template
}

function validate_inputs(){
    if ! [[ "$instances" =~ ^[0-9]+$ ]]; then
        msg_error "Invalid number of instances: $instances"
        exit 1
    fi
}

function cluster_setup_complete() {
    # Main script execution
    generate_main_vm_motd
    scale_and_rollout_deployments
    get_all_resources
    enter_main_vm
    clean_temp_files
    test_services
}

