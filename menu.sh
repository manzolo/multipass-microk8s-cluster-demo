#!/bin/bash

# Function for command selection
select_command() {
    OPTION=$(whiptail --title "Cluster Management" --menu "Select a command:" 15 60 5 \
    "Create Cluster" "Create a cluster" \
    "Destroy Cluster" "Destroy a cluster" \
    "Start Cluster" "Start a cluster" \
    "Stop Cluster" "Stop a cluster" \
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
                ./start_cluster.sh || echo "Error during execution of start_cluster.sh"
                ;;
            "Stop Cluster")
                ./stop_cluster.sh || echo "Error during execution of stop_cluster.sh"
                ;;
            "Exit")
                echo "Exiting..."
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac
    else
        echo "Exiting..."
    fi
}

# Execute the function
select_command