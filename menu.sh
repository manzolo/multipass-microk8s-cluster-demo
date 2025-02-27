#!/bin/bash

# Include functions
source $(dirname $0)/script/functions/common.sh
source $(dirname $0)/script/functions/node.sh
source $(dirname $0)/script/functions/vm.sh
source $(dirname $0)/script/functions/dns.sh
source $(dirname $0)/script/functions/nginx.sh
source $(dirname $0)/script/functions/rancher.sh
source $(dirname $0)/script/functions/cluster.sh

# Load default values and environment variables
source $(dirname $0)/script/functions/load_env.sh

# Function to display the menu
display_menu() {
    local title=$1
    local options=("${!2}")
    whiptail --title "$title" --menu "Select an option:" 25 80 15 "${options[@]}" 3>&1 1>&2 2>&3
}

# Function to handle cluster management
cluster_management() {
    local options=(
        "Create Cluster" "Create a Kubernetes cluster"
        "Start Cluster" "Start the Kubernetes cluster"
        "Stop Cluster" "Stop the Kubernetes cluster"
        "Shell on ${VM_MAIN_NAME}" "Shell on ${VM_MAIN_NAME}"
        "Add Cluster Node" "Add a node to the Kubernetes cluster"
        "Remove Cluster Node" "Remove a node from the Kubernetes cluster"
        "Show Cluster" "Show Cluster information"
        "Restore Cluster Health" "Restore Cluster Health"
        "Destroy Cluster" "Destroy the Kubernetes cluster"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Cluster Management" options[@])
        case "$choice" in
            "Create Cluster")
                ./create_kube_vms.sh && msg_info "Cluster creation done." || msg_error "Error during cluster creation."; press_any_key; echo
                ;;
            "Destroy Cluster")
                ./destroy_kube_vms.sh && msg_info "Cluster destruction done." || msg_error "Error during cluster destruction."; press_any_key; echo
                ;;
            "Start Cluster")
                start_cluster && msg_info "Cluster startup done." || msg_error "Error during cluster startup."
                sleep 5
                restart_microk8s_nodes
                show_cluster_info
                press_any_key
                echo
            ;;
            "Stop Cluster")
                stop_cluster && msg_info "Cluster shutdown done." || msg_error "Error during cluster shutdown.";
                show_cluster_info
                press_any_key
                echo
                ;;
            "Shell on ${VM_MAIN_NAME}")
                multipass shell "${VM_MAIN_NAME}" && msg_info "Shell ${VM_MAIN_NAME} OK." || msg_error "Error shell ${VM_MAIN_NAME}."
                press_any_key
                echo
                ;;
            "Add Cluster Node")
                add_node && msg_info "Node addition done." || msg_error "Error during node addition."
                restart_microk8s_nodes
                show_cluster_info
                press_any_key
                echo
                ;;
            "Remove Cluster Node")
                NODE_NAME=$(whiptail --inputbox "Enter the instance name of the node to remove (e.g., k8s-node3):" 8 50 --title "Node Name" 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                    remove_node "$NODE_NAME" && msg_info "Node removal done." || msg_error "Error during node removal."
                else
                    echo "Node removal cancelled."
                fi
                show_cluster_info
                press_any_key
                echo
                ;;
            "Show Cluster")
                show_cluster_info
                press_any_key
                echo
                ;;
            "Restore Cluster Health")
                restart_microk8s_nodes
                show_cluster_info
                press_any_key
                echo
                ;;
                
            "Back")
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

# Function to handle load balancer management
load_balancer_management() {
    local options=(
        "Create Nginx Load Balancer" "Create Nginx load balancer"
        "Start Nginx Load Balancer" "Start Nginx load balancer"
        "Stop Nginx Load Balancer" "Stop Nginx load balancer"
        "Destroy Nginx Load Balancer" "Destroy Nginx load balancer"
        "Shell on ${LOAD_BALANCE_HOSTNAME}" "Shell on ${LOAD_BALANCE_HOSTNAME}"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Load Balancer Management" options[@])
        case "$choice" in
            "Create Nginx Load Balancer")
                create_nginx_lb && msg_info "Nginx LB creation done." || msg_error "Error during Nginx LB creation."; press_any_key; echo
                ;;
            "Destroy Nginx Load Balancer")
                destroy_nginx_lb && msg_info "Nginx LB destruction done." || msg_error "Error during Nginx LB destruction."; press_any_key; echo
                ;;
            "Start Nginx Load Balancer")
                multipass start "${LOAD_BALANCE_HOSTNAME}" && msg_info "Nginx LB startup done." || msg_error "Error starting Nginx LB."; press_any_key; echo
                ;;
            "Stop Nginx Load Balancer")
                multipass stop "${LOAD_BALANCE_HOSTNAME}" && msg_info "Nginx LB shutdown done." || msg_error "Error stopping Nginx LB."
                press_any_key
                echo
                ;;
            "Shell on ${LOAD_BALANCE_HOSTNAME}")
                multipass shell "${LOAD_BALANCE_HOSTNAME}" && msg_info "Shell Nginx LB OK." || msg_error "Error shell Nginx LB."
                press_any_key
                echo
                ;;
            "Back")
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

# Function to handle Rancher management
rancher_management() {
    local options=(
        "Create Rancher" "Create Rancher"
        "Start Rancher" "Start Rancher"
        "Stop Rancher" "Stop Rancher"
        "Destroy Rancher" "Destroy Rancher"
        "Shell on ${RANCHER_HOSTNAME}" "Shell on ${RANCHER_HOSTNAME}"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Rancher Management" options[@])
        case "$choice" in
            "Create Rancher")
                create_rancher && msg_info "Rancher creation done." || msg_error "Error during Rancher creation."; press_any_key; echo
                ;;
            "Start Rancher")
                multipass start "${RANCHER_HOSTNAME}" && msg_info "Rancher startup done." || msg_error "Error starting Rancher."
                press_any_key
                echo
                ;;
            "Stop Rancher")
                multipass stop "${RANCHER_HOSTNAME}" && msg_info "Rancher shutdown done." || msg_error "Error stopping Rancher."
                press_any_key
                echo
                ;;
            "Shell on ${RANCHER_HOSTNAME}")
                multipass shell "${RANCHER_HOSTNAME}" && msg_info "Rancher shell OK." || msg_error "Error shell Rancher."
                press_any_key
                echo
                ;;
            "Destroy Rancher")
                destroy_rancher && msg_info "Rancher destruction done." || msg_error "Error during Rancher destruction."; press_any_key; echo
                ;;
            "Back")
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

# Function to handle DNS management
dns_management() {
    local options=(
        "Add DNS Configuration" "Add a custom local cluster DNS configuration"
        "Remove DNS Configuration" "Remove the custom local DNS configuration"
        "Start DNS server" "Start local cluster DNS server"
        "Stop DNS server" "Stop local cluster DNS server"
        "Shell on ${DNS_VM_NAME}" "Shell on ${DNS_VM_NAME}"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Rancher Management" options[@])
        case "$choice" in
            "Add DNS Configuration")
                echo "Adding DNS configuration..."
                add_dns_to_host
                ;;
            "Remove DNS Configuration")
                echo "Removing DNS configuration..."
                remove_dns_from_host
                ;;
            "Start DNS server")
                echo "Start local DNS server..."
                multipass start "${DNS_VM_NAME}" && msg_info "DNS server startup done." || msg_error "Error starting Nginx LB."
                press_any_key
                echo
                ;;
            "Stop DNS server")
                echo "Stop local DNS server..."
                multipass stop "${DNS_VM_NAME}" && msg_info "DNS server shutdown done." || msg_error "Error stopping Nginx LB."
                press_any_key
                echo
                ;;
            "Shell on ${DNS_VM_NAME}")
                multipass shell "${DNS_VM_NAME}" && msg_info "DNS server shell OK." || msg_error "Error DNS server shell."
                press_any_key
                echo
                ;;
            "Back")
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

# Main menu
main_menu() {
    local options=(
        "Cluster Management" "Manage Kubernetes cluster"
        "DNS Management" "Manage local cluster DNS server"
        "Load Balancer Management" "Manage Nginx Load Balancer"
        "Rancher Management" "Manage Rancher"
        "Uninstall All" "Destroy Kubernetes cluster, Nginx LB, and Rancher"
        "Exit" "Exit the program"
    )
    while true; do
        choice=$(display_menu "Kubernetes Cluster Management" options[@])
        case "$choice" in
            "Cluster Management")
                cluster_management
                ;;
            "DNS Management")
                dns_management
                ;;
            "Load Balancer Management")
                load_balancer_management
                ;;
            "Rancher Management")
                rancher_management
                ;;
            "Uninstall All")
                if whiptail --yesno "Are you sure you want to uninstall everything? This will destroy the Kubernetes cluster, Nginx LB, and Rancher." 10 60; then
                    ./destroy_kube_vms.sh && msg_info "Kubernetes cluster destruction done." || msg_error "Error during Kubernetes cluster destruction."
                    destroy_nginx_lb && msg_info "Nginx LB destruction done." || msg_error "Error during Nginx LB destruction."
                    destroy_rancher && msg_info "Rancher destruction done." || msg_error "Error during Rancher destruction."
                    press_any_key
                else
                    echo "Uninstall All cancelled."
                fi
                ;;
            "Exit")
                #echo "Exiting..."
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

# Execute the main menu
main_menu