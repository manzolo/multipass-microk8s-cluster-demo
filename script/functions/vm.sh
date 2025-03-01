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

    # Start the source VM after cloning
    #multipass start "$vm_src"
}

# Function to install Docker
install_docker() {
    local vm_name=$1
    msg_info "Installing Docker on $vm_name..."
    if ! multipass shell "$vm_name" > /dev/null 2>&1 <<EOF
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
        exit 1
    fi
}

function complete_microk8s_setup() {
    wait_for_microk8s_ready "$VM_MAIN_NAME"

    msg_info "=== Task 3: Completing microk8s setup ==="

    cat <<EOF > script/remote/__rollout_pods.sh
#!/bin/bash

# Variabili d'ambiente
deploy_demo_go=$deploy_demo_go
deploy_demo_php=$deploy_demo_php
deploy_static_site=$deploy_static_site
deploy_mariadb=$deploy_mariadb
deploy_mongodb=$deploy_mongodb
deploy_postgres=$deploy_postgres
deploy_elk=$deploy_elk
DNS_SUFFIX=$DNS_SUFFIX
export DNS_SUFFIX

# Funzione per eseguire un comando con un numero massimo di tentativi
function retry_command {
    local command="\$1"
    local max_attempts=3
    local attempt=1
    local wait_time=5

    while [ \$attempt -le \$max_attempts ]; do
        echo "Attempt \$attempt for: \$command"
        eval \$command

        if [ \$? -eq 0 ]; then
            echo "Deploy OK."
            return 0
        else
            echo "Error on deploy. Attempt \$attempt of \$max_attempts."
            sleep \$wait_time
        fi

        attempt=\$((attempt + 1))
    done

        echo "Command failed after \$max_attempts attempts."
        return 1
    }

    function k8s_deploy() {
        # Applica la configurazione per demo-go se deploy_demo_go è true
        if [ "\$deploy_demo_go" = true ]; then
            retry_command "cat /home/ubuntu/microk8s_demo_config/demo-go.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/demo-go -n demo-go"
        else
            echo "Skipping demo-go deployment."
        fi

        # Applica la configurazione per demo-php se deploy_demo_php è true
        if [ "\$deploy_demo_php" = true ]; then
            retry_command "cat /home/ubuntu/microk8s_demo_config/demo-php.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/demo-php -n demo-php"
        else
            echo "Skipping demo-php deployment."
        fi

        # Applica la configurazione per static-site se deploy_static_site è true
        if [ "\$deploy_static_site" = true ]; then
            retry_command "cat /home/ubuntu/microk8s_demo_config/static-site.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/static-site -n static-site"
        else
            echo "Skipping static-site deployment."
        fi

        # Applica la configurazione per mariadb + phpmyadmin se deploy_mariadb è true
        if [ "\$deploy_mariadb" = true ]; then
            echo "Mariadb: root - root"
            retry_command "cat /home/ubuntu/microk8s_demo_config/mariadb.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/phpmyadmin -n mariadb"
        else
            echo "Skipping mariadb + phpmyadmin deployment."
        fi

        # Applica la configurazione per mongodb se deploy_mongodb è true
        if [ "\$deploy_mongodb" = true ]; then
            retry_command "cat /home/ubuntu/microk8s_demo_config/mongodb.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/mongodb-express -n mongodb"
        else
            echo "Skipping mongodb deployment."
        fi

        # Applica la configurazione per postgres se deploy_postgres è true
        if [ "\$deploy_postgres" = true ]; then
            echo "Pgadmin: admin@example.com - password"
            retry_command "cat /home/ubuntu/microk8s_demo_config/postgres.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/pgadmin -n postgres"
        else
            echo "Skipping postgres deployment."
        fi

        # Applica la configurazione per ELK se deploy_elk è true
        if [ "\$deploy_elk" = true ]; then
            retry_command "cat /home/ubuntu/microk8s_demo_config/elk.yaml | envsubst | kubectl apply -f -"
            retry_command "kubectl rollout status deployment/kibana -n elk"
        else
            echo "Skipping ELK deployment."
        fi

        # Messaggio di avviso e attesa
        echo "Waiting for deploy complete..."
        sleep 10
    }

    k8s_deploy
EOF

    chmod +x script/remote/__rollout_pods.sh
    multipass transfer script/remote/__rollout_pods.sh $VM_MAIN_NAME:/home/ubuntu/rollout_pods.sh
    multipass transfer -r config $VM_MAIN_NAME:/home/ubuntu/microk8s_demo_config

    # Esegui lo script
    multipass exec $VM_MAIN_NAME -- /home/ubuntu/rollout_pods.sh

    #multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/rollout_pods.sh
    rm -rf script/remote/__rollout_pods.sh
}

function main_vm_setup(){
    # Create main VM
    create_vm $VM_MAIN_NAME "$mainRam" "$mainHddGb" "$mainCpu"

    add_machine_to_dns $VM_MAIN_NAME
    restart_dns_service

    # Copia il file sulla VM
    msg_info "=== Task 1: ${VM_MAIN_NAME} Setup ==="
    multipass transfer script/remote/__install_microk8s.sh $VM_MAIN_NAME:/home/ubuntu/install_microk8s.sh
    # Esegui lo script
    multipass exec $VM_MAIN_NAME -- /home/ubuntu/install_microk8s.sh

    multipass exec $VM_MAIN_NAME -- rm -rf /home/ubuntu/install_microk8s.sh

    multipass stop $VM_MAIN_NAME
}
