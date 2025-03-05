#!/bin/bash

#Include functions
source $(dirname $0)/script/functions/common.sh
source $(dirname $0)/script/functions/node.sh
source $(dirname $0)/script/functions/vm.sh
source $(dirname $0)/script/functions/dns.sh
source $(dirname $0)/script/functions/nginx.sh
source $(dirname $0)/script/functions/rancher.sh
source $(dirname $0)/script/functions/cluster.sh

# Load default values and environment variables
source $(dirname $0)/script/functions/load_env.sh

msg_warn "== Clean vms cluster"

multipass list | grep ${VM_NODE_PREFIX} | awk '{print $1}' | while read node; do
msg_warn "remove $node"
multipass delete --purge $node > /dev/null 2>&1
done

# Rimuovi le VM esistenti
remove_vm "${VM_MAIN_NAME}"
remove_vm "${DNS_VM_NAME}"
remove_vm "${CLIENT_HOSTNAME}"
remove_vm "${node_template}"

# Esegui il purge per rimuovere eventuali residui
msg_warn "Purging all deleted VMs..."
multipass purge > /dev/null 2>&1
if [ $? -eq 0 ]; then
    msg_warn "Purge completed successfully."
else
    msg_error "Failed to purge deleted VMs."
fi

# Mostra la lista delle VM esistenti
msg_warn "Current VM list:"
multipass list

msg_info "== Vms cluster clear"

# Ottieni il PID del processo padre
PARENT_PID=$(ps -o ppid= -p $$)

# Ottieni il nome del processo padre
PARENT_NAME=$(ps -o comm= -p $PARENT_PID)

if [[ "$PARENT_NAME" != "menu.sh" ]]; then
    press_any_key
    echo
fi