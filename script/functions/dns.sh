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

    msg_warn "$machine_name.$DNS_SUFFIX removed from $DNS_VM_NAME!"
}

restart_dns_service() {
    # Riavvia dnsmasq per applicare le modifiche
    msg_info "Riavvio di dnsmasq su $DNS_VM_NAME"
    multipass exec "$DNS_VM_NAME" -- sudo systemctl restart dnsmasq
}

function add_dns_to_host() {
    DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')
    CONF_DIR="/etc/systemd/resolved.conf.d"
    CONF_FILE="$CONF_DIR/multipass-dns.conf"

    # Crea la directory di configurazione se non esiste
    sudo mkdir -p "$CONF_DIR"

    # Crea il file di configurazione
    msg_info "Add DNS server $DNS_IP for .${DNS_SUFFIX} domain..."

    sudo tee ${CONF_FILE} > /dev/null 2>&1 <<EOF
    [Match]
    Domains=*.${DNS_SUFFIX}

    [Resolve]
    DNS=${DNS_IP}
EOF

    # Riavvia systemd-resolved per applicare le modifiche
    sudo systemctl restart systemd-resolved

    msg_info "Check with: resolvectl status"

    press_any_key
    echo
}

function remove_dns_from_host(){
    CONF_DIR="/etc/systemd/resolved.conf.d"
    CONF_FILE="$CONF_DIR/multipass-dns.conf"

    # Verifica se il file di configurazione esiste
    if [ -f "$CONF_FILE" ]; then
        msg_info "Removing DNS server configuration..."
        sudo rm "$CONF_FILE"
        
        # Riavvia systemd-resolved per applicare le modifiche
        sudo systemctl restart systemd-resolved
        
        msg_info "DNS configuration deleted. Check with: resolvectl status"
    else
        msg_error "$CONF_FILE not found."
    fi

    press_any_key
    echo
}

# Function to create DNS VM
create_dns_vm() {
    msg_info "Creating DNS VM: $DNS_VM_NAME"
    multipass launch "$DEFAULT_UBUNTU_VERSION" --name "$DNS_VM_NAME" --cpus 1 -m 1G --disk 5G
}

# Function to install and configure dnsmasq
install_dnsmasq() {
    local _DNS_IP=$(multipass info "$DNS_VM_NAME" | grep IPv4 | awk '{print $2}')

    msg_info "Installing dnsmasq on $DNS_VM_NAME"

    multipass exec "$DNS_VM_NAME" -- bash -c "
        sudo apt -qq update > /dev/null 2>&1
        sudo apt -yq install dnsmasq > /dev/null 2>&1

        # Disabilita systemd-resolved per evitare conflitti
        sudo systemctl stop systemd-resolved > /dev/null 2>&1
        sudo systemctl disable systemd-resolved > /dev/null 2>&1
        sudo mv /etc/resolv.conf /etc/resolv.conf.backup > /dev/null 2>&1

        # Configura dnsmasq

        cat <<EOF | sudo tee /etc/resolv.conf >/dev/null
nameserver 127.0.0.1
EOF

        cat <<EOF | sudo tee /etc/dnsmasq.d/local.conf >/dev/null
address=/${DNS_VM_NAME}.${DNS_SUFFIX}/${_DNS_IP}
EOF

        cat <<EOF | sudo tee /etc/dnsmasq.d/dns-public.conf >/dev/null
# Non usare i nameserver dal file /etc/resolv.conf
no-resolv

# Ignore /etc/hosts
no-hosts

# Imposta i nameserver upstream
server=1.1.1.1
server=8.8.8.8

# Abilita la risoluzione per il dominio locale .'${DNS_SUFFIX}'
domain='${DNS_SUFFIX}'
expand-hosts
local=/'${DNS_SUFFIX}'/

#Specifica un file addizionale per host locali personalizzati
addn-hosts=/etc/dnsmasq.d/local.conf
EOF
        #sudo sed -i -E \"/'${DNS_VM_NAME}'/d\" /etc/hosts
        sudo systemctl restart dnsmasq
        sudo dnsmasq --test
    "
}

# Function to generate MOTD
generate_dns_server_motd() {
    local MOTD_COMMANDS=$(cat <<EOF
$(tput setaf 6)$(tput bold)================================================
$(tput setaf 6)$(tput bold)  DNS Management Commands
$(tput setaf 6)$(tput bold)================================================
$(tput sgr0)

$(tput setaf 2)$(tput bold)🖥️  Check /etc/dnsmasq.d/local.conf:$(tput sgr0)
$(tput setaf 2)cat /etc/dnsmasq.d/local.conf$(tput sgr0)

$(tput setaf 3)$(tput bold)🖥️  Check /etc/dnsmasq.d/dns-public.conf:$(tput sgr0)
$(tput setaf 3)cat /etc/dnsmasq.d/dns-public.conf$(tput sgr0)

$(tput setaf 3)$(tput bold)📈  Check dnsmasq:$(tput sgr0)
$(tput setaf 3)sudo dnsmasq --test$(tput sgr0)

$(tput setaf 6)$(tput bold)👀  Check dnsmasq status:$(tput sgr0)
$(tput setaf 6)sudo systemctl status dnsmasq$(tput sgr0)

$(tput setaf 5)$(tput bold)🔄  Restart dnsmasq service:$(tput sgr0)
$(tput setaf 5)sudo systemctl restart dnsmasq$(tput sgr0)

$(tput sgr0)
EOF
    )

    msg_warn "Add ${DNS_VM_NAME} MOTD"
    multipass exec "$DNS_VM_NAME" -- sudo tee -a /home/ubuntu/.bashrc > /dev/null <<EOF
echo ""
echo "Commands to run on ${DNS_VM_NAME}:"
echo "$MOTD_COMMANDS"
EOF
}

function create_dns_server() {
    # Main script execution
    create_dns_vm
    install_dnsmasq
    generate_dns_server_motd

    msg_info "DNS VM $DNS_VM_NAME is ready!"
}
