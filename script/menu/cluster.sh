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