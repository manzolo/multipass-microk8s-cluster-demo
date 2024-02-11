#!/bin/bash

# Function for command selection
select_command() {
    while true; do
        OPTION=$(whiptail --title "Kubernetes Cluster Management" --menu "Select a command:" 20 80 13 \
        "Cluster Management:" "" \
        "Create Cluster" "Create a Kubernetes cluster" \
        "Start Cluster" "Start the Kubernetes cluster" \
        "Stop Cluster" "Stop the Kubernetes cluster" \
        "Add Cluster node" "Add a node to the Kubernetes cluster" \
        "Remove Cluster node" "Remove a node from the Kubernetes cluster" \
        "Destroy Cluster" "Destroy the Kubernetes cluster" \
        "Load Balancer Management:" "" \
        "Create Nginx Load Balancer" "Create Nginx load balancer" \
        "Destroy Nginx Load Balancer" "Destroy Nginx load balancer" \
        "Start Nginx Load Balancer" "Start Nginx load balancer" \
        "Stop Nginx Load Balancer" "Stop Nginx load balancer" \
        "Rancher Management:" "" \
        "Create Rancher" "Create Rancher" \
        "Destroy Rancher" "Destroy Rancher" \
        "Start Rancher" "Start Rancher" \
        "Stop Rancher" "Stop Rancher" \
        "Exit" "Exit the program" 3>&1 1>&2 2>&3)

        if [ $? -eq 0 ]; then
            case $OPTION in
                "Create Cluster")
                    ./create_kube_vms.sh || echo "Error during execution of create_kube_vms.sh"
                    ;;
                "Destroy Cluster")
                    ./destroy_kube_vms.sh || echo "Error during execution of destroy_kube_vms.sh"
                    ;;
                "Start Cluster")
                    ./cmd/start_cluster.sh || echo "Error during execution of start_cluster.sh"
                    ;;
                "Stop Cluster")
                    ./cmd/stop_cluster.sh || echo "Error during execution of stop_cluster.sh"
                    ;;
                "Add Cluster node")
                    ./cmd/add_node.sh || echo "Error during execution of add_node.sh"
                    ;;
                "Remove Cluster node")
                    NODE_NAME=$(whiptail --inputbox "Enter the instance name of the node to remove (e.g., k8s-node3):" 8 50 --title "Node Name" 3>&1 1>&2 2>&3)
                    if [ $? -eq 0 ]; then
                        ./cmd/remove_node.sh "$NODE_NAME" || echo "Error during execution of remove_node.sh"
                    else
                        echo "Exiting..."
                    fi
                    ;;
                "Create Nginx Load Balancer")
                    ./cmd/create_nginx_lb.sh || echo "Error during execution of create_nginx_lb.sh"
                    ;;
                "Destroy Nginx Load Balancer")
                    ./cmd/destroy_nginx_lb.sh || echo "Error during execution of destroy_nginx_lb.sh"
                    ;;
                "Start Nginx Load Balancer")
                    multipass start nginx-cluster-balancer || echo "Error starting Nginx load balancer"
                    ;;
                "Stop Nginx Load Balancer")
                    multipass stop nginx-cluster-balancer || echo "Error stopping Nginx load balancer"
                    ;;
                "Create Rancher")
                    ./cmd/create_rancher.sh || echo "Error during execution of create_rancher.sh"
                    ;;
                "Destroy Rancher")
                    ./cmd/destroy_rancher.sh || echo "Error during execution of destroy_rancher.sh"
                    ;;
                "Start Rancher")
                    multipass start rancher || echo "Error starting rancher"
                    ;;
                "Stop Rancher")
                    multipass stop rancher || echo "Error stopping rancher"
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
            echo "Exiting..."
            break
        fi
    done
}

# Execute the function
select_command
