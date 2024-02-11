#!/bin/bash

# Function for command selection
select_command() {
    while true; do
        OPTION=$(whiptail --title "Cluster Management" --menu "Select a command:" 15 60 9 \
        "Cluster Management:" "" \
        "Create Cluster" "Create a cluster" \
        "Start Cluster" "Start a cluster" \
        "Stop Cluster" "Stop a cluster" \
        "Add Cluster node" "Add a cluster node" \
        "Destroy Cluster" "Destroy a cluster" \
        "Load Balancer Management:" "" \
        "Create Nginx Load Balancer" "Create Nginx load balancer" \
        "Destroy Nginx Load Balancer" "Destroy Nginx load balancer" \
        "Start Nginx Load Balancer" "Start Nginx load balancer" \
        "Stop Nginx Load Balancer" "Stop Nginx load balancer" \
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