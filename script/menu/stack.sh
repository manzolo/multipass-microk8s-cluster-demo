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
