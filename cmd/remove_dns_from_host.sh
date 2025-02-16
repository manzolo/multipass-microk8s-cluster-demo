#!/bin/bash

# Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

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

read -n 1 -s -r -p "Press any key to continue..."
echo