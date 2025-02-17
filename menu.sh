#!/bin/bash

# Include functions
source $(dirname $0)/script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/script/__load_env.sh

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
        "Add Cluster Node" "Add a node to the Kubernetes cluster"
        "Remove Cluster Node" "Remove a node from the Kubernetes cluster"
        "Destroy Cluster" "Destroy the Kubernetes cluster"
        "Add DNS Configuration" "Add a custom local cluster DNS configuration"
        "Remove DNS Configuration" "Remove the custom local DNS configuration"
        "Start DNS server" "Start local cluster DNS server"
        "Stop DNS server" "Stop local cluster DNS server"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Cluster Management" options[@])
        case "$choice" in
            "Create Cluster")
                ./create_kube_vms.sh && echo "Cluster creation done." || echo "Error during cluster creation."
                ;;
            "Destroy Cluster")
                ./destroy_kube_vms.sh && echo "Cluster destruction done." || echo "Error during cluster destruction."
                ;;
            "Start Cluster")
                ./cmd/start_cluster.sh && echo "Cluster startup done." || echo "Error during cluster startup."
                ;;
            "Stop Cluster")
                ./cmd/stop_cluster.sh && echo "Cluster shutdown done." || echo "Error during cluster shutdown."
                ;;
            "Add Cluster Node")
                ./cmd/add_node.sh && echo "Node addition done." || echo "Error during node addition."
                ;;
            "Remove Cluster Node")
                NODE_NAME=$(whiptail --inputbox "Enter the instance name of the node to remove (e.g., k8s-node3):" 8 50 --title "Node Name" 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                    ./cmd/remove_node.sh "$NODE_NAME" && echo "Node removal done." || echo "Error during node removal."
                else
                    echo "Node removal cancelled."
                fi
                ;;
            "Add DNS Configuration")
                echo "Adding DNS configuration..."
                ./cmd/add_dns_to_host.sh
                ;;
            "Remove DNS Configuration")
                echo "Removing DNS configuration..."
                ./cmd/remove_dns_from_host.sh
                ;;
            "Start DNS server")
                echo "Start local DNS server..."
                multipass start "${DNS_VM_NAME}" && echo "DNS server startup done." || echo "Error starting Nginx LB."
                ;;
            "Stop DNS server")
                echo "Stop local DNS server..."
                multipass stop "${DNS_VM_NAME}" && echo "DNS server shutdown done." || echo "Error stopping Nginx LB."
                ;;
            "Back")
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    done
}

# Function to handle load balancer management
load_balancer_management() {
    local options=(
        "Create Nginx Load Balancer" "Create Nginx load balancer"
        "Destroy Nginx Load Balancer" "Destroy Nginx load balancer"
        "Start Nginx Load Balancer" "Start Nginx load balancer"
        "Stop Nginx Load Balancer" "Stop Nginx load balancer"
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Load Balancer Management" options[@])
        case "$choice" in
            "Create Nginx Load Balancer")
                ./cmd/create_nginx_lb.sh && echo "Nginx LB creation done." || echo "Error during Nginx LB creation."
                ;;
            "Destroy Nginx Load Balancer")
                ./cmd/destroy_nginx_lb.sh && echo "Nginx LB destruction done." || echo "Error during Nginx LB destruction."
                ;;
            "Start Nginx Load Balancer")
                multipass start "${LOAD_BALANCE_HOSTNAME}" && echo "Nginx LB startup done." || echo "Error starting Nginx LB."
                ;;
            "Stop Nginx Load Balancer")
                multipass stop "${LOAD_BALANCE_HOSTNAME}" && echo "Nginx LB shutdown done." || echo "Error stopping Nginx LB."
                ;;
            "Back")
                break
                ;;
            *)
                echo "Invalid choice."
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
        "Back" "Return to main menu"
    )
    while true; do
        choice=$(display_menu "Rancher Management" options[@])
        case "$choice" in
            "Create Rancher")
                ./cmd/create_rancher.sh && echo "Rancher creation done." || echo "Error during Rancher creation."
                ;;
            "Destroy Rancher")
                ./cmd/destroy_rancher.sh && echo "Rancher destruction done." || echo "Error during Rancher destruction."
                ;;
            "Start Rancher")
                multipass start "${RANCHER_HOSTNAME}" && echo "Rancher startup done." || echo "Error starting Rancher."
                ;;
            "Stop Rancher")
                multipass stop "${RANCHER_HOSTNAME}" && echo "Rancher shutdown done." || echo "Error stopping Rancher."
                ;;
            "Back")
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    done
}

# Main menu
main_menu() {
    local options=(
        "Cluster Management" "Manage Kubernetes cluster"
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
            "Load Balancer Management")
                load_balancer_management
                ;;
            "Rancher Management")
                rancher_management
                ;;
            "Uninstall All")
                if whiptail --yesno "Are you sure you want to uninstall everything? This will destroy the Kubernetes cluster, Nginx LB, and Rancher." 10 60; then
                    ./destroy_kube_vms.sh && echo "Kubernetes cluster destruction done." || echo "Error during Kubernetes cluster destruction."
                    ./cmd/destroy_nginx_lb.sh && echo "Nginx LB destruction done." || echo "Error during Nginx LB destruction."
                    ./cmd/destroy_rancher.sh && echo "Rancher destruction done." || echo "Error during Rancher destruction."
                else
                    echo "Uninstall All cancelled."
                fi
                ;;
            "Exit")
                echo "Exiting..."
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    done
}

# Execute the main menu
main_menu