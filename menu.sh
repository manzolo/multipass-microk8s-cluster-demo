#!/bin/bash

# Include functions
source $(dirname $0)/script/functions/common.sh
source $(dirname $0)/script/functions/node.sh
source $(dirname $0)/script/functions/vm.sh
source $(dirname $0)/script/functions/dns.sh
source $(dirname $0)/script/functions/nginx.sh
source $(dirname $0)/script/functions/rancher.sh
source $(dirname $0)/script/functions/cluster.sh
source $(dirname $0)/script/functions/motd.sh

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
                generate_main_vm_motd
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
                # Ottieni la lista dei nodi con prefisso VM_NODE_PREFIX
                local node_list=$(multipass list | grep "${VM_NODE_PREFIX}" | awk '{print $1}')
                local node_array=($(echo "$node_list"))
                local num_nodes=${#node_array[@]}

                # Se non ci sono nodi, mostra un avviso e torna al menu principale
                if [[ $num_nodes -eq 0 ]]; then
                    msg_warn "No nodes with prefix '${VM_NODE_PREFIX}' found."
                    press_any_key
                    echo
                    show_cluster_info
                    continue
                fi

                # Crea il menu con i nomi dei nodi e la descrizione con lo stato
                local menu_items=()
                for node in "${node_array[@]}"; do
                    local node_status=$(multipass info "$node" | grep "State:" | awk '{print $2}')
                    menu_items+=("$node") # Aggiungi il nome del nodo
                    menu_items+=("Remove Cluster Node (Status: $node_status)") # Aggiungi la descrizione con lo stato
                done

                # Crea il messaggio con il numero di nodi e una descrizione delle operazioni
                local menu_message="Select a node to remove:\n\n"
                menu_message+="Active nodes: $num_nodes\n\n"
                menu_message+="This operation will:\n"
                menu_message+="1. Cordon the node (mark it as unschedulable).\n"
                menu_message+="2. Drain the node (safely evict all workloads).\n"
                menu_message+="3. Remove the node from the cluster.\n"
                menu_message+="4. Delete the node VM from Multipass."

                # Mostra il menu e cattura la selezione
                local selected_node=$(whiptail --menu "$menu_message" 20 80 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                local return_code=$?

                # Gestisci la selezione
                if [[ $return_code -eq 0 ]]; then
                    # Verifica che selected_node non sia vuoto
                    if [[ -z "$selected_node" ]]; then
                        msg_error "No node selected. Please try again."
                    else
                        # Ottieni lo stato del nodo selezionato
                        local selected_node_status=$(multipass info "$selected_node" 2>/dev/null | grep "State:" | awk '{print $2}')
                        
                        # Verifica se il nodo esiste
                        if [[ -z "$selected_node_status" ]]; then
                            msg_error "Node '$selected_node' does not exist."
                        else
                            # Conferma la rimozione del nodo con stato
                            if whiptail --yesno "Are you sure you want to remove the following node?\n\nNode: $selected_node\nStatus: $selected_node_status" 12 70; then
                                # Esegui la rimozione del nodo
                                if remove_node "$selected_node"; then
                                    msg_info "Node '$selected_node' removed successfully."
                                else
                                    msg_error "Failed to remove node '$selected_node'."
                                fi
                            else
                                msg_info "Node '$selected_node' removal cancelled."
                            fi
                        fi
                    fi
                elif [[ $return_code -eq 1 ]]; then
                    # Torna al menu principale se viene premuto "Annulla"
                    msg_info "Node removal cancelled."
                    continue
                else
                    msg_error "An unexpected error occurred during node selection."
                fi

                # Mostra le informazioni aggiornate del cluster e attendi un input
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

# Function to handle stack management
stack_management() {
    local config_dir="config"
    local options=()
    local services=()

    # Itera su ogni file YAML nella cartella dei config
    for file in "$config_dir"/*.yaml; do
        service=$(basename "$file" .yaml)
        human_service=$(echo "$service" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) {$i=toupper(substr($i,1,1)) substr($i,2)}; print}')
        services+=("$human_service" "$service")
        options+=("${human_service} Stack" "Manage ${human_service} stack")
    done

    options+=("Back" "Return to the main menu")

    while true; do
        choice=$(display_menu "Stack Management" options[@])
        if [[ "$choice" == "Back" ]]; then
            break
        fi

        for ((i=0; i<${#services[@]}; i+=2)); do
            if [[ "$choice" == "${services[i]} Stack" ]]; then
                manage_stack "${services[i]}" "${services[i+1]}"
                break
            fi
        done
    done
}

# Function to manage a specific stack
# Function to manage a specific stack
manage_stack() {
    local stack_name=$1
    local namespace=$2
    local options=(
        "Check Status" "Show the status of all resources in the $stack_name stack"
        "View Pod Logs" "View logs of a specific pod in the $stack_name stack"
        "Restart Stack" "Restart all pods in the $stack_name stack"
        "Scale Stack" "Scale the number of replicas in the $stack_name stack"
        "View Exposed Services" "Show URLs or IPs of exposed services in the $stack_name stack"
        "Describe Stack" "Show detailed information about the $stack_name stack"
        "Monitor Resource Usage" "Show resource usage of pods in the $stack_name stack"
        "Back" "Return to the previous menu"
    )

    while true; do
        choice=$(display_menu "$stack_name Stack Management" options[@])
        case "$choice" in
            "Check Status")
                if multipass list | grep -q "${VM_MAIN_NAME}"; then
                    multipass exec "${VM_MAIN_NAME}" -- kubectl get all -o wide -n "$namespace" && \
                    msg_info "Status of $stack_name stack in namespace $namespace." || \
                    msg_error "Failed to check status of $stack_name stack."
                else
                    msg_info "Multipass VM ${VM_MAIN_NAME} is not running. Cannot check status."
                fi
                press_any_key
                echo
                ;;
            "View Pod Logs")
                local pod_name=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get pods -n "$namespace" -o name | head -n 1)
                if [[ -n "$pod_name" ]]; then
                    multipass exec "${VM_MAIN_NAME}" -- kubectl logs "$pod_name" -n "$namespace" && \
                    msg_info "Logs for pod $pod_name in namespace $namespace." || \
                    msg_error "Failed to view logs for pod $pod_name."
                else
                    msg_info "No pods found in namespace $namespace."
                fi
                press_any_key
                echo
                ;;
            "Restart Stack")
                multipass exec "${VM_MAIN_NAME}" -- kubectl rollout restart deployment -n "$namespace" && \
                msg_info "Restarted all deployments in the $stack_name stack." || \
                msg_error "Failed to restart deployments in the $stack_name stack."
                press_any_key
                echo
                ;;
            "Scale Stack")
                # Ottieni il nome del deployment nel namespace specificato
                local deployment_name=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get deployments -n "$namespace" -o jsonpath='{.items[0].metadata.name}')
                
                if [[ -z "$deployment_name" ]]; then
                    msg_error "No deployment found in namespace $namespace."
                else
                    # Chiedi all'utente il numero di repliche
                    local replicas=$(whiptail --inputbox "Enter the number of replicas:" 10 60 3>&1 1>&2 2>&3)
                    
                    if [[ -n "$replicas" ]]; then
                        # Esegui il comando di scale
                        multipass exec "${VM_MAIN_NAME}" -- kubectl scale deployment "$deployment_name" --replicas="$replicas" -n "$namespace" && \
                        msg_info "Scaled deployment '$deployment_name' in the $stack_name stack to $replicas replicas." || \
                        msg_error "Failed to scale deployment '$deployment_name' in the $stack_name stack."
                    else
                        msg_info "Scale operation cancelled."
                    fi
                fi
                press_any_key
                echo
                ;;
            "View Exposed Services")
                multipass exec "${VM_MAIN_NAME}" -- kubectl get ingress,svc -n "$namespace" && \
                msg_info "Exposed services in the $stack_name stack." || \
                msg_error "Failed to retrieve exposed services."
                press_any_key
                echo
                ;;
            "Describe Stack")
                multipass exec "${VM_MAIN_NAME}" -- kubectl describe deployment -n "$namespace" && \
                msg_info "Detailed information about the $stack_name stack." || \
                msg_error "Failed to describe the $stack_name stack."
                press_any_key
                echo
                ;;
            "Monitor Resource Usage")
                multipass exec "${VM_MAIN_NAME}" -- kubectl top pod -n "$namespace" && \
                msg_info "Resource usage of pods in the $stack_name stack." || \
                msg_error "Failed to monitor resource usage."
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

# Function to handle .env file management
env_management() {
    while true; do
        source .env
        if [ -f .env.local ]; then
            source .env.local
        fi

        local options=()

        for file in config/*.yaml; do
            service=$(basename "$file" .yaml)
            env_var="DEPLOY_$(echo "$service" | tr '[:lower:]-' '[:upper:]_')"

            if grep -q "^$env_var=" .env; then
                current_value=$(grep "^$env_var=" .env | cut -d= -f2)
            elif [ -f .env.local ] && grep -q "^$env_var=" .env.local; then
                current_value=$(grep "^$env_var=" .env.local | cut -d= -f2)
            else
                current_value="false"
            fi

            options+=("Set $env_var" "$current_value")
        done

        options+=("Back" "Return to main menu")

        choice=$(display_menu "ENV Management" options[@])

        if [[ "$choice" == "Back" ]]; then
            break
        fi

        key=$(echo "$choice" | sed 's/^Set //')
        toggle_env_value "$key"
    done
}

# Function to toggle a boolean value in .env or .env.local and apply/delete Kubernetes resources
toggle_env_value() {
    local key=$1
    local file=".env"

    if [ -f .env.local ]; then
        file=".env.local"
    else
        touch .env.local
        file=".env.local"
    fi

    if grep -q "^$key=" "$file"; then
        current_value=$(grep "^$key=" "$file" | cut -d= -f2)
    else
        echo "$key=false" >> "$file"
        current_value="false"
    fi

    if [[ "$current_value" == "true" ]]; then
        new_value="false"
        action="delete"
    else
        new_value="true"
        action="apply"
    fi

    if grep -q "^$key=" "$file"; then
        sed -i "s/^$key=.*/$key=$new_value/" "$file"
    else
        echo "$key=$new_value" >> "$file"
    fi

    msg_info "$key toggled to $new_value."

    local namespace=$(echo "$key" | cut -d_ -f2- | tr '[:upper:]_' '[:lower:]-')
    local yaml_file="microk8s_demo_config/${namespace}.yaml"

    deploy_stack "$namespace" "$yaml_file" "$action"

    press_any_key
    echo
}

function deploy_stack() {
    local namespace=$1
    local yaml_file=$2
    local action=$3

    if multipass list | grep -q "${VM_MAIN_NAME}"; then
        if [[ "$action" == "delete" ]]; then
            multipass exec "${VM_MAIN_NAME}" -- kubectl delete -f "$yaml_file" && \
            msg_info "Deleted resources from $yaml_file." || \
            msg_error "Failed to delete resources from $yaml_file."
        else
            multipass exec "${VM_MAIN_NAME}" -- bash -c "
                export DNS_SUFFIX='${DNS_SUFFIX}'
                cat '/home/ubuntu/$yaml_file' | envsubst | kubectl apply -f -
            " && \
            msg_info "Applied $yaml_file." || \
            msg_error "Failed to apply $yaml_file."
        fi
    else
        msg_info "Multipass VM ${VM_MAIN_NAME} is not running. Only .env file was updated."
    fi
}

# Function to handle stack and environment management
stack_and_env_management() {
    local options=(
        "Stack Management" "Manage all stacks (MariaDB, ELK, MongoDB, etc.)"
        "Env Management" "Manage .env file settings"
        "Back" "Return to the main menu"
    )
    while true; do
        choice=$(display_menu "Stack & Environment Management" options[@])
        case "$choice" in
            "Stack Management")
                stack_management
                ;;
            "Env Management")
                env_management
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

# Function to handle client management
client_management() {
    local options=(
        "Install" "Install client VM"
        "RDP" "Enter via RDP on client VM"
        "Remove" "Uninstall client VM"
        "Back" "Return to the main menu"
    )

    while true; do
        choice=$(display_menu "Client Management" options[@])
        case "$choice" in
            "Install")
                client_vm_setup
                ;;
            "RDP")
                client_vm_rdp
                ;;
            "Remove")
                client_vm_remove
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
        "Stack Management" "Manage all stacks (MariaDB, ELK, MongoDB, etc.)"
        "Client Management" "Ubuntu client for test"
        "Show Cluster" "Show Cluster information"
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
            "Client Management")
                client_management
                ;;
            "Stack Management")
                stack_and_env_management
                ;;
            "Show Cluster")
                show_cluster_info
                press_any_key
                echo
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
                break
                ;;
            *)
                break
                ;;
        esac
    done
}

create_env_local
# Execute the main menu
main_menu