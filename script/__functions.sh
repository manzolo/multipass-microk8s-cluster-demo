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

# Function to create a VM
create_vm() {
    local vm_name=$1
    local ram=$2
    local hdd=$3
    local cpu=$4

    msg_warn "Creating VM: $vm_name"
    if ! multipass launch $DEFAULT_UBUNTU_VERSION -m $ram -d $hdd -c $cpu -n $vm_name; then
        msg_error "Failed to create VM: $vm_name"
        exit 1
    fi
    multipass info $vm_name
}

# Function to clone a VM
function clone_vm() {
    local vm_dst=$1
    local vm_src=$VM_MAIN_NAME  # Default source VM

    # Check if $1 contains a number
    if [[ $vm_dst =~ ([0-9]+)$ ]]; then
        # Extract the number from $1
        local num=${BASH_REMATCH[1]}

        # Find the last existing VM
        local last_existing_vm=$(multipass list | grep "$VM_NODE_PREFIX" | awk '{print $1}' | sed "s/${VM_NODE_PREFIX}//" | sort -n | tail -1)

        # If there are existing VMs, use the last one as the source
        if [[ -n "$last_existing_vm" ]]; then
            vm_src="${VM_NODE_PREFIX}${last_existing_vm}"
        fi
    fi

    # Stop the source VM before cloning
    if multipass list | grep -q "$vm_src"; then
        multipass stop "$vm_src"
    else
        msg_warn "Source VM $vm_src does not exist. Skipping stop."
    fi

    # Log the cloning operation
    msg_warn "Clone VM: $vm_src -> $vm_dst"

    # Construct and execute the clone command
    clone_command="multipass clone ${vm_src} -n ${vm_dst}"
    #echo "Executing: $clone_command"
    if ! $clone_command; then
        msg_error "Failed to clone VM: $vm_src"
        exit 1
    fi

    # Start the destination VM after cloning
    multipass start "$vm_dst"
}

# Function to mount host directory
mount_host_dir() {
    local vm_name=$1

    msg_warn "Mounting host directory to $vm_name"
    if ! multipass mount ${HOST_DIR_NAME} $vm_name; then
        msg_error "Failed to mount directory to $vm_name"
        exit 1
    fi
}

# Function to mount host directory
unmount_host_dir() {
    local vm_name=$1

    msg_warn "Unmounting host directory to $vm_name"
    if ! multipass umount $vm_name:$(multipass info ${vm_name} | grep Mounts | awk '{print $4}'); then
        msg_error "Failed to mount directory to $vm_name"
        exit 1
    fi
}

# Funzione per aggiungere una macchina al DNS
add_machine_to_dns() {
    local machine_name=$1
    local machine_ip=$2  # Secondo parametro opzionale: IP della macchina

    DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')

    # Se l'IP non è fornito, prova a ottenerlo automaticamente (solo se è una VM Multipass)
    if [ -z "$machine_ip" ]; then
        if multipass list | grep -q "$machine_name"; then
            machine_ip=$(multipass info "$machine_name" | grep IPv4 | awk '{print $2}')
            if [ -z "$machine_ip" ]; then
                msg_error "Unable to obtain $machine_name IP"
                return 1
            fi
        else
            msg_error "No IP provided and $machine_name is not a Multipass VM. Please provide an IP."
            return 1
        fi
    fi

    # Configura il resolver DNS sulla macchina (solo se è una VM Multipass)
    if multipass list | grep -q "$machine_name"; then
        msg_warn "Configuring DNS resolver on $machine_name to use $DNS_VM_NAME ($DNS_IP)"
        
        # Generate a unique filename (e.g., based on the suffix)
        config_filename="dns-${DNS_SUFFIX//./-}.conf"

        # Create the configuration content in a variable
        config_content="
[Resolve]
DNS=${DNS_IP}"

        multipass exec "$machine_name" -- bash -c '
                sudo mkdir -p /etc/systemd/resolved.conf.d

                cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/'"$config_filename"' >/dev/null
'"$config_content"'        
EOF

                sudo systemctl restart systemd-resolved
                #systemd-resolve --status
            '

    else
        msg_warn "$machine_name is not a Multipass VM. Skipping DNS resolver configuration."
    fi

    # Aggiungi la voce DNS al file di configurazione di dnsmasq
    msg_warn "Add $machine_name.$DNS_SUFFIX -> $machine_ip to DNS on $DNS_VM_NAME"
    multipass exec "$DNS_VM_NAME" -- sudo bash -c "echo 'address=/$machine_name.$DNS_SUFFIX/$machine_ip' >> /etc/dnsmasq.d/local.conf"

    # Riavvia dnsmasq per applicare le modifiche
    msg_warn "Restart dnsmasq on $DNS_VM_NAME"
    multipass exec "$DNS_VM_NAME" -- sudo systemctl restart dnsmasq

    msg_info "$machine_name.$DNS_SUFFIX added successfully to DNS on $DNS_VM_NAME!"
}

remove_machine_from_dns() {
    local machine_name=$1

    msg_warn "Remove $machine_name.$DNS_SUFFIX from DNS on $DNS_VM_NAME"
    
    # Controlla se la VM esiste
    if ! multipass info "$DNS_VM_NAME" &>/dev/null; then
        msg_warn "$DNS_VM_NAME not exists. Skip to remove $machine_name.$DNS_SUFFIX"
        return 0
    fi

    # Rimuovi la voce DNS dal file di configurazione di dnsmasq
    multipass exec "$DNS_VM_NAME" -- sudo sed -i "/address=\/$machine_name.$DNS_SUFFIX\//d" /etc/dnsmasq.d/local.conf

    # Riavvia dnsmasq per applicare le modifiche
    msg_info "Riavvio di dnsmasq su $DNS_VM_NAME"
    multipass exec "$DNS_VM_NAME" -- sudo systemctl restart dnsmasq

    msg_warn "$machine_name.$DNS_SUFFIX removed from $DNS_VM_NAME!"
}

function get_available_node_number() {
  local existing_nodes
  local available_num=1

  # Ottieni i numeri dei nodi esistenti e ordinali
  existing_nodes=$(multipass list | grep "$VM_NODE_PREFIX" | awk '{print $1}' | sed "s/${VM_NODE_PREFIX}//" | sort -n)

  # Trova il primo numero disponibile
  if [ -n "$existing_nodes" ]; then
    for num in $existing_nodes; do
      if [[ $num -eq $available_num ]]; then
        available_num=$((available_num + 1))
      else
        break
      fi
    done
  fi

  echo "$available_num"
}

function wait_for_microk8s_ready() {
  local vm_name="$1"

  msg_warn "Waiting for microk8s to be ready on $vm_name..."
  while ! multipass exec "$vm_name" -- microk8s status --wait-ready > /dev/null 2>&1; do
    sleep 10
  done

  msg_info "MicroK8s is ready on $vm_name."
}

function restart_microk8s_nodes() {
  local prefix="$VM_NODE_PREFIX"
  local counter
  local retries=3  # Numero massimo di tentativi
  instances=$(get_max_node_instance)
  msg_info "Restarting MicroK8s on $instances nodes..."

  for ((counter = 1; counter <= instances; counter++)); do
    local node_name="${prefix}${counter}"

    msg_warn "Restarting MicroK8s on $node_name..."

    # Verifica se il nodo è raggiungibile
    if ! multipass exec "$node_name" -- "true" > /dev/null 2>&1; then
      msg_error "Node $node_name is not reachable. Skipping restart."
      continue # Salta questo nodo e passa al successivo
    fi

    # Esegue l'ispezione per identificare eventuali problemi (con tentativi)
    msg_warn "Running microk8s inspect on $node_name..."
    local attempt=1
    while [[ $attempt -le $retries ]]; do
      if multipass exec "$node_name" -- sudo microk8s inspect > /dev/null 2>&1; then
        break # Comando riuscito, esci dal ciclo
      else
        #msg_error "Attempt $attempt: Failed microk8s inspect on $node_name."
        attempt=$((attempt + 1))
        if [[ $attempt -gt $retries ]]; then
          continue
          #msg_error "All attempts failed for microk8s inspect on $node_name. Skipping this node."
          #continue 2 # Salta questo nodo e passa al successivo
        fi
      fi
      sleep 2
    done

    # Riavvia MicroK8s (con tentativi)
    msg_warn "Restarting MicroK8s on $node_name..."
    attempt=1
    while [[ $attempt -le $retries ]]; do
      if multipass exec "$node_name" -- sudo snap restart microk8s > /dev/null 2>&1; then
        break # Comando riuscito, esci dal ciclo
      else
        #msg_error "Attempt $attempt: Failed to restart MicroK8s on $node_name."
        attempt=$((attempt + 1))
        if [[ $attempt -gt $retries ]]; then
          continue
          #msg_error "All attempts failed to restart MicroK8s on $node_name. Skipping this node."
          #continue 2 # Salta questo nodo e passa al successivo
        fi
      fi
      sleep 2
    done

    # Attende che MicroK8s sia pronto (con tentativi)
    msg_warn "Waiting for MicroK8s to be ready on $node_name..."
    attempt=1
    while [[ $attempt -le $retries ]]; do
      if wait_for_microk8s_ready "$node_name"; then
        msg_info "MicroK8s restarted and ready on $node_name."
        break # Comando riuscito, esci dal ciclo
      else
        msg_error "Attempt $attempt: MicroK8s failed to restart and become ready on $node_name."
        attempt=$((attempt + 1))
        if [[ $attempt -gt $retries ]]; then
          continue
          #msg_error "All attempts failed for MicroK8s to become ready on $node_name. Skipping this node."
          #continue 2 # Salta questo nodo e passa al successivo
        fi
      fi
      sleep 2
    done
    msg_info "MicroK8s restart process completed."
  done
}

function get_max_node_instance() {
  local prefix="$VM_NODE_PREFIX"
  local existing_nodes
  local max_instance

  # Ottieni i numeri dei nodi esistenti e ordinali
  existing_nodes=$(multipass list | grep "$prefix" | awk '{print $1}' | sed "s/${prefix}//" | sort -n)

  # Trova il numero massimo di istanza
  if [ -n "$existing_nodes" ]; then
    max_instance=$(echo "$existing_nodes" | tail -n 1)
  else
    max_instance=0 # Se non ci sono nodi, il massimo è 0
  fi

  echo "$max_instance"
}


function show_cluster_info() {
# Colori
local RED='\033[0;31m'
local GREEN='\033[0;32m'
local YELLOW='\033[1;33m'
local BLUE='\033[0;34m'
local NC='\033[0m' # No Color

# Intestazione della tabella
echo
echo
printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"
printf "${BLUE}%-20s | %-15s | %-30s${NC}\n" "VM Name" "IP" "Multipass Shell"
printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"

# Estrai le informazioni e formatta la tabella
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

printf "${BLUE}-----------------------------------------------------------------------------------${NC}\n"
echo
}