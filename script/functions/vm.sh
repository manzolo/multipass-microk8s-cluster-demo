#!/bin/bash

set -e

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

function remove_vm() {
    local vm_name=$1

    # Verifica se la VM esiste
    if multipass list | grep -q "$vm_name"; then
        msg_warn "Removing VM: $vm_name..."
        multipass delete --purge "$vm_name" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            msg_warn "VM $vm_name removed successfully."
        else
            msg_error "Failed to remove VM: $vm_name"
        fi
    else
        msg_warn "VM $vm_name does not exist. Skipping removal."
    fi
}

# Function to clone a VM
function clone_vm() {
    local new_vm_name="$1"
    local source_vm="$2"

    multipass clone "$source_vm" --name "$new_vm_name"
    if [ $? -ne 0 ]; then
        msg_error "Failed to clone VM: $source_vm"
        return 1
    fi
}

function install_docker() {
    local vm_name=$1
    msg_info "Installing Docker on $vm_name..."
    if ! multipass shell "$vm_name" <<EOF
#!/bin/bash
set -e
# Remove old Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y \$pkg
done

# Add Docker's official GPG key
sudo apt update -qq
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
echo \
  "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu || true # Ignore if group doesn't exist yet
sudo systemctl unmask docker
sudo systemctl enable docker
sudo systemctl start docker
EOF
    then
        msg_error "Failed to enable Docker on $vm_name."
        return 1
    fi
}

function complete_microk8s_setup() {
    wait_for_microk8s_ready "$VM_MAIN_NAME"
    msg_info "=== Task 3: Completing microk8s setup ==="

    multipass transfer -r config $VM_MAIN_NAME:/home/ubuntu/microk8s_demo_config

    declare -A deployments # Dichiarazione dell'array associativo

    deployments["demo-go"]=""
    deployments["demo-php"]=""
    deployments["static-site"]=""
    deployments["mariadb"]="deployment=phpmyadmin"
    deployments["mongodb"]="deployment=mongodb-express"
    deployments["postgres"]="deployment=pgadmin"
    deployments["elk"]="deployment=kibana"
    deployments["redis"]="deployment=redis-commander"
    deployments["rabbitmq"]=""
    deployments["jenkins"]=""

    function deploy_app() {
        local app_name="$1"
        local deploy_info="${deployments[$app_name]}"

        local deployment="$app_name" # Default deployment name
        if [ -n "$deploy_info" ]; then
            deployment=$(echo "$deploy_info" | awk -F'deployment=' '{print $2}')
        fi

        local deploy_var="DEPLOY_$(echo "$app_name" | tr '[:lower:]-' '[:upper:]_')"

        if [ -z "${!deploy_var}" ]; then
            msg_warn "Variable $deploy_var is not defined. Skipping $app_name deployment."
            return 0
        fi

        if eval "[ \${$deploy_var} = 'true' ]"; then
            if ! multipass exec $VM_MAIN_NAME -- bash -c "cat /home/ubuntu/microk8s_demo_config/$app_name.yaml | envsubst | kubectl apply -f -"; then
                msg_error "Failed to apply $app_name"
                return 1
            fi

            # Verifica lo stato del deployment
            if ! multipass exec $VM_MAIN_NAME -- bash -c "kubectl rollout status deployment/$deployment -n $app_name --timeout=60s"; then
                msg_error "Failed to rollout deployment $deployment"
                return 1
            fi
        else
            msg_warn "Skipping $app_name deployment."
        fi
    }

    for app_name in "${!deployments[@]}"; do
        deploy_app "$app_name"
    done
}

function k8s_vm_setup(){
    VM_NAME=$1
    multipass transfer script/remote/__install_microk8s.sh $VM_NAME:/home/ubuntu/install_microk8s.sh
    multipass exec $VM_NAME -- /home/ubuntu/install_microk8s.sh
    multipass exec $VM_NAME -- rm -rf /home/ubuntu/install_microk8s.sh
}

function main_vm_setup(){
    create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"
    add_machine_to_dns $VM_MAIN_NAME
    restart_dns_service
    msg_info "=== Task 1: ${VM_MAIN_NAME} Setup ==="
    k8s_vm_setup $VM_MAIN_NAME
    multipass stop $VM_MAIN_NAME
}

function k8s_vm_save_template(){
    multipass clone $VM_MAIN_NAME -n ${node_template}
    multipass start $VM_MAIN_NAME
}

function client_vm_setup() {
    local MEM="1Gb"
    local DISK="10Gb"
    local CPUS="1"

    # Ottieni le impostazioni locali dell'host
    local host_locale=$(locale | awk -F= '/^LANG=/ {print $2}')
    if [[ -z "$host_locale" ]]; then
        host_locale="en_US.UTF-8"  # Imposta un valore predefinito
    fi
    local host_language=$(echo "$host_locale" | cut -d. -f1)

    # Ottieni il layout di tastiera dell'host
    local host_keyboard_layout=$(localectl status | grep "X11 Layout" | awk '{print $3}')

    # Crea la VM
    create_vm "$CLIENT_HOSTNAME" "$MEM" "$DISK" "$CPUS"
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to create VM: $CLIENT_HOSTNAME"
        return 1
    fi

    # Aggiungi al DNS
    add_machine_to_dns "$CLIENT_HOSTNAME"
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to add $CLIENT_HOSTNAME to DNS"
        return 1
    fi

    # Riavvia il servizio DNS
    restart_dns_service
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to restart DNS service"
        return 1
    fi

    # Avvia la VM
    multipass start "$CLIENT_HOSTNAME"
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to start VM: $CLIENT_HOSTNAME"
        return 1
    fi

    # Installa software e configura (xfce4, browser, xrdp, .xsession)
    multipass exec "$CLIENT_HOSTNAME" -- bash -c "
        sudo apt update -qq &&
        sudo apt install -yqq xfce4 firefox xrdp &&
        echo 'xfce4-session' > ~/.xsession &&
        chmod +x ~/.xsession &&
        sudo systemctl restart xrdp &&
        echo 'ubuntu:ubuntu' | sudo chpasswd
    "
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to install software and configure VM: $CLIENT_HOSTNAME"
        return 1
    fi

    # Configura la localizzazione
    multipass exec "$CLIENT_HOSTNAME" -- bash -c "
        sudo locale-gen $host_locale &&
        sudo update-locale LANG=$host_locale
    "
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to configure locale on VM: $CLIENT_HOSTNAME"
        return 1
    fi

   # Configura il layout della tastiera
    multipass exec "$CLIENT_HOSTNAME" -- bash -c '
        sudo sed -i "s/XKBLAYOUT=\".*\"/XKBLAYOUT=\"'"$host_keyboard_layout"'\"/" /etc/default/keyboard &&
        sudo dpkg-reconfigure -f noninteractive keyboard-configuration &&
        echo "setxkbmap '"$host_keyboard_layout"'" >> ~/.bashrc
    '
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to configure keyboard layout on VM: $CLIENT_HOSTNAME"
        return 1
    fi

    # Riavvia la VM per applicare le modifiche
    multipass stop "$CLIENT_HOSTNAME"
    multipass start "$CLIENT_HOSTNAME"
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to restart VM: $CLIENT_HOSTNAME"
        return 1
    fi

    sleep 5

    msg_info "Client VM setup complete. Connect using RDP."
}

function client_vm_rdp() {
    local REMMINA_FILE="/tmp/${CLIENT_HOSTNAME}.remmina"
    multipass start "$CLIENT_HOSTNAME"

    # Ottieni l'indirizzo IP
    local VM_IP=$(get_vm_ip "$CLIENT_HOSTNAME")
    if [[ -z "$VM_IP" ]]; then
        msg_error "Failed to get IP address for VM: $CLIENT_HOSTNAME"
        return 1
    fi

    # Crea il file .remmina temporaneo con l'IP corretto
    cat <<EOF > /tmp/k8s-client.remmina
[remmina]
protocol=RDP
name=${CLIENT_HOSTNAME}
server=${VM_IP}
username=ubuntu
password=ubuntu
resolution=800x600
disable-encryption=1
ignore-certificate=1
security=
console=0
sharefolder=
shareprinter=0
shareport=0
sharedevice=0
sharebuffer=0
color-depth=32
sound=1
gateway_server=
gateway_username=
gateway_password=
EOF

    # Avvia Remmina in background e sopprimi l'output
    nohup remmina -c "$REMMINA_FILE" > /dev/null 2>&1 &
    REMMINA_PID=$!
    disown "$REMMINA_PID"

    if [[ $REMMINA_PID -eq 0 ]]; then
        msg_error "Failed to start Remmina"
        rm -f "$REMMINA_FILE"
        return 1
    fi

    msg_info "RDP connection to $CLIENT_HOSTNAME started in background (PID: $REMMINA_PID)."

    # Funzione per eliminare il file .remmina quando Remmina termina
    cleanup() {
        if [[ -f "$REMMINA_FILE" ]]; then
            rm -f "$REMMINA_FILE"
            msg_info "Removed temporary Remmina file."
        fi
    }

    # Imposta il trap per chiamare cleanup quando Remmina termina
    trap cleanup EXIT
}

function client_vm_remove() {
    # Rimuovi dal DNS
    remove_machine_from_dns "$CLIENT_HOSTNAME"
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to remove $CLIENT_HOSTNAME from DNS"
        return 1
    fi

    # Riavvia il servizio DNS
    restart_dns_service
    if [[ $? -ne 0 ]]; then
        msg_error "Failed to restart DNS service"
        return 1
    fi

    # Arresta la VM
    multipass stop --force "$CLIENT_HOSTNAME"
    if [[ $? -ne 0 ]]; then
        msg_warn "Failed to stop VM: $CLIENT_HOSTNAME"
    fi

    # Elimina la VM
    multipass delete --purge "$CLIENT_HOSTNAME"
    if [[ $? -ne 0 ]]; then
        msg_warn "Failed to delete VM: $CLIENT_HOSTNAME"
    fi

    # Purge Multipass
    multipass purge
    if [[ $? -ne 0 ]]; then
        msg_warn "Failed to purge Multipass"
    fi

    msg_info "Client VM removed."
}

client_vm_stop() {
    multipass stop --force "$CLIENT_HOSTNAME"
}

client_vm_start() {
    multipass start "$CLIENT_HOSTNAME"
}