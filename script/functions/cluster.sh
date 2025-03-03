#!/bin/bash

set -e

function start_cluster() {
    msg_warn "Check prerequisites..."
    #Check prerequisites
    check_command_exists "multipass"

    instance_names="${DNS_VM_NAME} ${VM_MAIN_NAME}"
    instances=$(get_num_instances)
    for ((counter=1; counter<=instances; counter++)); do
        instance_names="${instance_names} ${VM_NODE_PREFIX}${counter}"
    done

    multipass start $instance_names

    msg_info "All VMs started."
    #show_cluster_info
}

function stop_cluster() {
    msg_warn "Check prerequisites..."
    #Check prerequisites
    check_command_exists "multipass"

    instance_names="${DNS_VM_NAME} ${VM_MAIN_NAME}"
    instances=$(get_num_instances)
    for ((counter=1; counter<=instances; counter++)); do
        instance_names="${instance_names} ${VM_NODE_PREFIX}${counter}"
    done

    if [ $force_stop_vm = true ]; then
        for instance in $instance_names; do
            force_stop_vm $instance
        done
    else
        multipass stop $instance_names
    fi

    msg_info "All VMs stopped."

    #show_cluster_info
}

# Function to test services
test_services() {
    local IP=$(get_vm_ip "$VM_MAIN_NAME")

    if [ "$deploy_demo_go" = true ]; then
        local NODEPORT_GO=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-go -n demo-go)
        msg_warn "Testing Golang service:"
        msg_info "curl -s http://$IP:$NODEPORT_GO"
        
        # Clean temp files
        local temp_file="${INSTALL_DIR}/script/_test.sh"
        trap "rm -f $temp_file" EXIT
        echo "curl -s http://$IP:$NODEPORT_GO" > "$temp_file"
        chmod +x "$temp_file"
        "$temp_file"
    fi

    if [ "$deploy_demo_php" = true ]; then
        local NODEPORT_PHP=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services demo-php -n demo-php)
        msg_warn "Testing PHP service:"
        msg_info "http://$IP:$NODEPORT_PHP"
    fi
}

# Function to scale and rollout deployments
scale_and_rollout_deployments() {
    msg_warn "Scaling and rolling out deployments..."
    # Applica la configurazione per demo-go se DEPLOY_DEMO_GO è true
    if [ "$deploy_demo_go" = "true" ]; then
        multipass exec "${VM_MAIN_NAME}" -- kubectl scale deployment demo-go --replicas=6 -n demo-go
        multipass exec "${VM_MAIN_NAME}" -- kubectl rollout status deployment/demo-go -n demo-go
    fi
    # Applica la configurazione per demo-PHP se DEPLOY_DEMO_PHP è true
    if [ "$deploy_demo_php" = "true" ]; then
        multipass exec "${VM_MAIN_NAME}" -- kubectl scale deployment demo-php --replicas=6 -n demo-php
        multipass exec "${VM_MAIN_NAME}" -- kubectl rollout status deployment/demo-php -n demo-php
    fi
}

# Function to get all resources
get_all_resources() {
    msg_warn "Getting all resources..."

    if [ "$deploy_demo_go" = "true" ]; then
       multipass exec "${VM_MAIN_NAME}" -- kubectl get all -o wide -n demo-go
    fi

    if [ "$deploy_demo_php" = "true" ]; then
        multipass exec "${VM_MAIN_NAME}" -- kubectl get all -o wide -n demo-php
    fi
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

