#!/bin/bash

# Include functions
source $(dirname $0)/../script/__functions.sh

# Load default values and environment variables
source $(dirname $0)/../script/__load_env.sh

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