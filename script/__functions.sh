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
    read -n 1 -s -r -p "Press any key to continue"
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
clone_vm() {
    local vm_src=$VM_MAIN_NAME
    local vm_dst=$1

    msg_warn "Clone VM: $vm_src"
    if ! multipass clone $vm_src -n $vm_dst; then
        msg_error "Failed to clone VM: $vm_src"
        exit 1
    fi
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
