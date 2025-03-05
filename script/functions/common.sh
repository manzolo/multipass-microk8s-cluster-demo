#!/bin/bash

# Load .env file if it exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs) # Export variables from .env, ignoring comments
fi

NC=$'\033[0m' # No Color

function msg_info() {
  local GREEN=$'\033[0;32m'
  printf "%s\n" "${GREEN}${*}${NC}" >&2
}

function msg_warn() {
  local BROWN=$'\033[0;33m'
  printf "%s\n" "${BROWN}${*}${NC}" >&2
}

function msg_error() {
  local RED=$'\033[0;31m'
  printf "%s\n" "${RED}${*}${NC}" >&2
}

function msg_fatal() {
  msg_error "${*}"
  exit 1
}

function press_any_key() {
    read -n 1 -s -r -p "Press any key to continue..."
}

check_command_exists() {
    if ! command -v $1 &> /dev/null
    then
        msg_error "$1 could not be found!"
        exit 1
    fi
}

run_command_on_node() {
    node_name=$1
    command=$2
    multipass exec -v ${node_name} -- ${command}
}

function create_env_local() {
  local env_file=".env.local"

  if [[ ! -f "$env_file" ]]; then
    cat <<EOF > "$env_file"
DEPLOY_DEMO_GO=true
DEPLOY_DEMO_PHP=true
DEPLOY_STATIC_SITE=true
DEPLOY_MARIADB=true
EOF
    echo "Created $env_file with default values."
  fi
}


# Funzione per eseguire un comando con un numero massimo di tentativi
function retry_command {
    local command="$1"
    local max_attempts=3
    local attempt=1
    local wait_time=5

    while [ $attempt -le $max_attempts ]; do
        #echo "Attempt $attempt for: $command"
        eval $command

        if [ $? -eq 0 ]; then
            #echo "Deploy OK."
            return 0
        else
            echo "Error on deploy. Attempt $attempt of $max_attempts."
            sleep $wait_time
        fi

        attempt=$((attempt + 1))
    done

    echo "Command failed after $max_attempts attempts."
    return 1
}

# Funzione per ottenere l'IP della vm
force_stop_vm() {
    vm_name=$1
    multipass stop --force ${vm_name}
}

function get_num_instances() {
  local count=$(multipass list | grep "${VM_NODE_PREFIX}" | wc -l)
  if [ "$count" -eq 0 ]; then
    echo "$instances" # Restituisce il valore pre-esistente di $instances
  else
    echo "$count" # Restituisce il conteggio di wc -l
  fi
}

# Funzione per ottenere l'IP della vm
get_vm_ip() {
    vm_name=$1
    echo $(multipass info "${vm_name}" | grep IPv4 | awk '{print $2}')
}

function print_service_table() {
    IP=$(get_vm_ip "$VM_MAIN_NAME")

    echo
    echo
    printf "${BLUE}------------------------------------------------------------------------------------${NC}\n"
    printf "${BLUE}%-20s | %-15s | %-10s | %-30s${NC}\n" "Service Name" "Namespace" "NodePort" "URL"
    printf "${BLUE}------------------------------------------------------------------------------------${NC}\n"

    local main_state=$(multipass info k8s-main | grep "State:" | awk '{print $2}')

    if [[ "$main_state" == "Running" ]]; then

        # Recupera tutti i servizi e le loro informazioni in un'unica chiamata, escludendo i namespace di sistema
        local services=$(multipass exec "${VM_MAIN_NAME}" -- kubectl get services --all-namespaces -o json --field-selector metadata.namespace!=kube-system,metadata.namespace!=kube-public,metadata.namespace!=kube-node-lease,metadata.namespace!=default)

        # Estrai le informazioni usando jq
        local service_info=$(echo "$services" | jq -r '.items[] | [.metadata.name, .metadata.namespace, .spec.ports[0].nodePort] | @tsv')

        # Stampa le righe della tabella
        while IFS=$'\t' read -r service_name namespace nodeport; do
            if [ -n "$nodeport" ]; then
                printf "%-20s | %-15s | %-10s | ${BLUE}http://$IP:$nodeport${NC}\n" "$service_name" "$namespace" "$nodeport"
            else
                printf "%-20s | %-15s | %-10s | ${BLUE}Service not deployed${NC}\n" "$service_name" "$namespace" "-"
            fi
        done <<< "$service_info"

    else
        printf "${YELLOW}k8s-main is not running. Kubernetes info not available.${NC}\n"
    fi

    printf "${BLUE}------------------------------------------------------------------------------------${NC}\n"
    echo
}

function print_multipass_vm() {
    # Intestazione della tabella Multipass
    echo
    echo
    printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"
    printf "${BLUE}%-20s | %-15s | %-30s${NC}\n" "VM Name" "IP" "Multipass Shell"
    printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"

    # Estrai le informazioni e formatta la tabella Multipass
    multipass list | awk '/k8s-/ {
        name = $1
        state = $2
        ip = $3
        if (state == "Running") {
            printf "'${GREEN}'%-20s'${NC}' | '${YELLOW}'%-15s'${NC}' | multipass shell %s\n", name, ip, name
        } else {
            printf "'${RED}'%-20s'${NC}' | '${YELLOW}'%-15s'${NC}' | '${RED}'Stopped'${NC}'\n", name, "N/A"
        }
    }'
}

function print_cluster_info(){
    # Intestazione della tabella Kubernetes
    echo
    echo
    printf "${BLUE}---------------------------------------------------------------${NC}\n"
    printf "${BLUE}%-20s | %-15s | %-10s${NC}\n" "Node Name" "Status" "Version"
    printf "${BLUE}---------------------------------------------------------------${NC}\n"

    # Verifica lo stato di k8s-main
    local main_state=$(multipass info k8s-main | grep "State:" | awk '{print $2}')

    # Estrai le informazioni e formatta la tabella Kubernetes solo se k8s-main è in esecuzione
    if [[ "$main_state" == "Running" ]]; then
        multipass exec k8s-main -- kubectl get nodes | awk 'NR>1 {
            name = $1
            status = $2
            roles = $3
            version = $5
            if (status == "Ready") {
                printf "'${GREEN}'%-20s'${NC}' | '${GREEN}'%-15s'${NC}' | %-10s\n", name, status, version
            } else {
                printf "'${RED}'%-20s'${NC}' | '${RED}'%-15s'${NC}' | %-10s\n", name, status, version
            }
        }'
    else
        printf "${YELLOW}k8s-main is not running. Kubernetes info not available.${NC}\n"
    fi

    printf "${BLUE}---------------------------------------------------------------${NC}\n"
    echo

}

function show_cluster_info() {
    # Colori
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color
    
    print_multipass_vm

    print_cluster_info
    
    print_service_table
}