#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

# Include functions
# shellcheck source=script/functions/common.sh
source "${SCRIPT_DIR}/script/functions/common.sh"
# shellcheck source=script/functions/node.sh
source "${SCRIPT_DIR}/script/functions/node.sh"
# shellcheck source=script/functions/vm.sh
source "${SCRIPT_DIR}/script/functions/vm.sh"
# shellcheck source=script/functions/dns.sh
source "${SCRIPT_DIR}/script/functions/dns.sh"
# shellcheck source=script/functions/nginx.sh
source "${SCRIPT_DIR}/script/functions/nginx.sh"
# shellcheck source=script/functions/rancher.sh
source "${SCRIPT_DIR}/script/functions/rancher.sh"
# shellcheck source=script/functions/cluster.sh
source "${SCRIPT_DIR}/script/functions/cluster.sh"

# Load default values and environment variables
# shellcheck source=script/functions/load_env.sh
source "${SCRIPT_DIR}/script/functions/load_env.sh"

msg_warn "== Clean vms cluster"

node_list=$(multipass list | grep "${VM_NODE_PREFIX}" | awk '{print $1}' || true)
for node in $node_list; do
    msg_warn "remove $node"
    multipass delete --purge "$node" > /dev/null 2>&1 || true
done

# Rimuovi le VM esistenti
remove_vm "${VM_MAIN_NAME}"
remove_vm "${DNS_VM_NAME}"
remove_vm "${CLIENT_HOSTNAME}"
remove_vm "${node_template}"

# Esegui il purge per rimuovere eventuali residui
msg_warn "Purging all deleted VMs..."
if multipass purge > /dev/null 2>&1; then
    msg_warn "Purge completed successfully."
else
    msg_error "Failed to purge deleted VMs."
fi

# Mostra la lista delle VM esistenti
msg_warn "Current VM list:"
multipass list

msg_info "== Vms cluster clear"

# Ottieni il nome del processo padre usando $PPID (variabile built-in bash)
PARENT_NAME=""
if [[ -f "/proc/$PPID/comm" ]]; then
    PARENT_NAME=$(cat "/proc/$PPID/comm" 2>/dev/null || true)
fi

if [[ "$PARENT_NAME" != "menu.sh" ]]; then
    press_any_key
    echo
fi