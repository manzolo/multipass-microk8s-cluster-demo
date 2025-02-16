#!/bin/bash

# Function for command selection
select_command() {
    while true; do
        OPTION=$(whiptail --title "Kubernetes Cluster Management" --menu "Select a command:" 25 80 15 \
        "Cluster Management:" "" \
        "Create Cluster" "Create a Kubernetes cluster" \
        "Start Cluster" "Start the Kubernetes cluster" \
        "Stop Cluster" "Stop the Kubernetes cluster" \
        "Add Cluster Node" "Add a node to the Kubernetes cluster" \
        "Remove Cluster Node" "Remove a node from the Kubernetes cluster" \
        "Destroy Cluster" "Destroy the Kubernetes cluster" \
        "Add DNS Configuration" "Add a custom local cluster DNS configuration" \
        "Remove DNS Configuration" "Remove the custom local DNS configuration" \
        "Load Balancer Management:" "" \
        "Create Nginx Load Balancer" "Create Nginx load balancer" \
        "Destroy Nginx Load Balancer" "Destroy Nginx load balancer" \
        "Start Nginx Load Balancer" "Start Nginx load balancer" \
        "Stop Nginx Load Balancer" "Stop Nginx load balancer" \
        "Rancher Management:" "" \
        "Create Rancher" "Create Rancher" \
        "Start Rancher" "Start Rancher" \
        "Stop Rancher" "Stop Rancher" \
        "Destroy Rancher" "Destroy Rancher" \
        "Uninstall All" "Destroy Kubernetes cluster, Nginx LB, and Rancher" \
        "Exit" "Exit the program" 3>&1 1>&2 2>&3)

        if [ $? -eq 0 ]; then
            case "$OPTION" in  # Double quotes around $OPTION
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
                        echo "Node removal cancelled." # More descriptive message
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
                "Create Nginx Load Balancer")
                    ./cmd/create_nginx_lb.sh && echo "Nginx LB creation done." || echo "Error during Nginx LB creation."
                    ;;
                "Start Nginx Load Balancer")
                    multipass start nginx-cluster-balancer && echo "Nginx LB startup done." || echo "Error starting Nginx LB."
                    ;;
                "Stop Nginx Load Balancer")
                    multipass stop nginx-cluster-balancer && echo "Nginx LB shutdown done." || echo "Error stopping Nginx LB."
                    ;;
                "Destroy Nginx Load Balancer")
                    ./cmd/destroy_nginx_lb.sh && echo "Nginx LB destruction done." || echo "Error during Nginx LB destruction."
                    ;;
                "Create Rancher")
                    ./cmd/create_rancher.sh && echo "Rancher creation done." || echo "Error during Rancher creation."
                    ;;
                "Destroy Rancher")
                    ./cmd/destroy_rancher.sh && echo "Rancher destruction done." || echo "Error during Rancher destruction."
                    ;;
                "Start Rancher")
                    multipass start rancher && echo "Rancher startup done." || echo "Error starting Rancher."
                    ;;
                "Stop Rancher")
                    multipass stop rancher && echo "Rancher shutdown done." || echo "Error stopping Rancher."
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
        else
            echo "Operation cancelled." # More descriptive message
            break
        fi
    done
}

# Execute the function
select_command